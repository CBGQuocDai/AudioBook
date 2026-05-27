package org.backend.payment.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.common.response.ApiResponse;
import org.backend.payment.config.StripeProperties;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.backend.payment.exception.BadRequestException;
import org.backend.payment.service.PaymentService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;

/**
 * REST controller acting as the Stripe webhook receiver endpoint.
 * Safely processes async payment notifications from Stripe to update the internal system's payment state.
 * Employs constant-time signature verification and prevents webhook retry storms during locking conflicts.
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/payments/stripe")
public class PaymentWebhookController {

    /**
     * Service processing core payment domain logic.
     */
    private final PaymentService paymentService;

    /**
     * Configuration properties for Stripe.
     */
    private final StripeProperties stripeProperties;

    /**
     * JSON utility parser.
     */
    private final ObjectMapper objectMapper;

    /**
     * Receives and processes an incoming Stripe webhook event.
     * Verifies the Stripe-Signature header prior to parsing.
     *
     * @param payload the raw JSON webhook event body.
     * @param stripeSignature the 'Stripe-Signature' header containing timestamp and HMAC-SHA256 signature.
     * @return {@link ResponseEntity} acknowledging the event back to Stripe (200 OK or 400 Bad Request).
     */
    @PostMapping("/webhook")
    public ResponseEntity<?> handleStripeWebhook(
            @RequestBody String payload,
            @RequestHeader("Stripe-Signature") String stripeSignature) {
        try {
            // Verify webhook signature
            if (!verifyWebhookSignature(payload, stripeSignature)) {
                log.warn("Webhook signature verification failed");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(ApiResponse.builder()
                                .message("Webhook signature verification failed")
                                .build());
            }

            // Parse the event JSON
            JsonNode event = objectMapper.readTree(payload);
            String eventType = event.get("type").asText();
            JsonNode data = event.get("data").get("object");

            log.info("Processing Stripe webhook event. eventType={}", eventType);

            // Handle payment_intent.succeeded event
            if ("payment_intent.succeeded".equals(eventType)) {
                return handlePaymentIntentSucceeded(data);
            }

            // Handle payment_intent.payment_failed event
            if ("payment_intent.payment_failed".equals(eventType)) {
                return handlePaymentIntentFailed(data);
            }

            // Acknowledge other events but don't process them
            log.debug("Received unhandled Stripe event type: {}", eventType);
            return ResponseEntity.ok(ApiResponse.builder()
                    .message("Event received but not processed")
                    .build());

        } catch (Exception e) {
            log.error("Error processing Stripe webhook", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.builder()
                            .message("Error processing webhook: " + e.getMessage())
                            .build());
        }
    }

    /**
     * Handles payment success events (payment_intent.succeeded).
     * Updates local status to SUCCESS. Returns 200 on locking failures to prevent unnecessary Stripe retries.
     *
     * @param data the inner event object containing PaymentIntent details.
     * @return response indicating processing success.
     */
    private ResponseEntity<?> handlePaymentIntentSucceeded(JsonNode data) {
        try {
            String stripePaymentIntentId = data.get("id").asText();

            if (stripePaymentIntentId == null || stripePaymentIntentId.isBlank()) {
                log.warn("Payment intent ID is missing in webhook");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(ApiResponse.builder()
                                .message("Payment intent ID is missing")
                                .build());
            }

            PaymentDetailResponse response = paymentService.updatePaymentFromStripeEvent(
                    stripePaymentIntentId,
                    "payment_intent.succeeded",
                    null
            );

            log.info("Payment succeeded via webhook. paymentId={}, stripePaymentIntentId={}",
                    response.getPaymentId(), stripePaymentIntentId);

            return ResponseEntity.ok(ApiResponse.<PaymentDetailResponse>builder()
                    .data(response)
                    .message("Payment marked as successful")
                    .build());

        } catch (Exception e) {
            if (e instanceof ObjectOptimisticLockingFailureException) {
                log.warn("Concurrent webhook update detected for payment_intent.succeeded. Returning 200 to avoid retry storm.");
                return ResponseEntity.ok(ApiResponse.builder()
                        .message("Concurrent update detected, event acknowledged")
                        .build());
            }
            log.error("Error handling payment_intent.succeeded", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.builder()
                            .message("Error processing payment success: " + e.getMessage())
                            .build());
        }
    }

    /**
     * Handles payment failure events (payment_intent.payment_failed).
     * Extracts failure details and marks local state as FAILED.
     *
     * @param data the inner event object containing PaymentIntent details.
     * @return response indicating processing success.
     */
    private ResponseEntity<?> handlePaymentIntentFailed(JsonNode data) {
        try {
            String stripePaymentIntentId = data.get("id").asText();

            if (stripePaymentIntentId == null || stripePaymentIntentId.isBlank()) {
                log.warn("Payment intent ID is missing in webhook");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(ApiResponse.builder()
                                .message("Payment intent ID is missing")
                                .build());
            }

            // Extract failure reason from the last error if available
            String failureReason = "Payment failed";
            JsonNode lastPaymentError = data.get("last_payment_error");
            if (lastPaymentError != null && lastPaymentError.get("message") != null) {
                failureReason = lastPaymentError.get("message").asText();
            }

            PaymentDetailResponse response = paymentService.updatePaymentFromStripeEvent(
                    stripePaymentIntentId,
                    "payment_intent.payment_failed",
                    failureReason
            );

            log.info("Payment failed via webhook. paymentId={}, stripePaymentIntentId={}, failureReason={}",
                    response.getPaymentId(), stripePaymentIntentId, failureReason);

            return ResponseEntity.ok(ApiResponse.<PaymentDetailResponse>builder()
                    .data(response)
                    .message("Payment marked as failed")
                    .build());

        } catch (Exception e) {
            if (e instanceof ObjectOptimisticLockingFailureException) {
                log.warn("Concurrent webhook update detected for payment_intent.payment_failed. Returning 200 to avoid retry storm.");
                return ResponseEntity.ok(ApiResponse.builder()
                        .message("Concurrent update detected, event acknowledged")
                        .build());
            }
            log.error("Error handling payment_intent.payment_failed", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.builder()
                            .message("Error processing payment failure: " + e.getMessage())
                            .build());
        }
    }

    /**
     * Verifies the webhook signature using HMAC-SHA256.
     * <p>
     * Stripe sends a Stripe-Signature header with the format:
     * t=timestamp,v1=signature
     * <p>
     * The signature is computed using HMAC-SHA256 with the webhook secret as the key
     * and the signed content as: {timestamp}.{payload}
     *
     * @param payload the raw JSON webhook event body.
     * @param stripeSignature the raw Stripe-Signature header string.
     * @return true if the computed signature matches the header; false otherwise.
     */
    private boolean verifyWebhookSignature(String payload, String stripeSignature) {
        try {
            String webhookSecret = stripeProperties.getWebhookSecret();

            if (webhookSecret == null || webhookSecret.isBlank()) {
                log.error("Stripe webhook secret is not configured");
                return false;
            }

            // Parse the signature header: t=<timestamp>,v1=<signature>
            String[] parts = stripeSignature.split(",");
            String timestamp = null;
            String receivedSignature = null;

            for (String part : parts) {
                if (part.startsWith("t=")) {
                    timestamp = part.substring(2);
                } else if (part.startsWith("v1=")) {
                    receivedSignature = part.substring(3);
                }
            }

            if (timestamp == null || receivedSignature == null) {
                log.warn("Invalid Stripe-Signature header format");
                return false;
            }

            // Compute the expected signature
            String signedContent = timestamp + "." + payload;
            String expectedSignature = computeSignature(signedContent, webhookSecret);

            // Compare signatures using constant-time comparison to prevent timing attacks
            boolean isValid = constantTimeEquals(expectedSignature, receivedSignature);

            if (!isValid) {
                log.warn("Webhook signature mismatch. Expected={}, Received={}", expectedSignature, receivedSignature);
            }

            return isValid;

        } catch (Exception e) {
            log.error("Error verifying webhook signature", e);
            return false;
        }
    }

    /**
     * Computes HMAC-SHA256 hex signature.
     *
     * @param data payload block to sign.
     * @param secret signing secret.
     * @return computed hex string.
     * @throws Exception if HmacSHA256 algorithm is not supported.
     */
    private String computeSignature(String data, String secret) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        SecretKeySpec keySpec = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        mac.init(keySpec);
        byte[] bytes = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return HexFormat.of().formatHex(bytes);
    }

    /**
     * Constant-time string comparison to prevent timing attacks.
     *
     * @param a first string to compare.
     * @param b second string to compare.
     * @return true if equal; false otherwise.
     */
    private boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null) {
            return a == b;
        }

        byte[] aBytes = a.getBytes(StandardCharsets.UTF_8);
        byte[] bBytes = b.getBytes(StandardCharsets.UTF_8);

        if (aBytes.length != bBytes.length) {
            return false;
        }

        int result = 0;
        for (int i = 0; i < aBytes.length; i++) {
            result |= aBytes[i] ^ bBytes[i];
        }

        return result == 0;
    }
}
