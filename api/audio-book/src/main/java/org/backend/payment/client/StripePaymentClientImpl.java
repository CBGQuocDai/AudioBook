package org.backend.payment.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.payment.config.StripeProperties;
import org.backend.payment.exception.PaymentIntegrationException;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

/**
 * Implementation of {@link StripePaymentClient} utilizing RestTemplate to communicate with Stripe REST API.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class StripePaymentClientImpl implements StripePaymentClient {

    /**
     * Endpoint URL for Stripe PaymentIntents API.
     */
    private static final String STRIPE_PAYMENT_INTENT_API = "https://api.stripe.com/v1/payment_intents";

    /**
     * Configuration properties for Stripe.
     */
    private final StripeProperties stripeProperties;

    /**
     * Internal REST client.
     */
    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * {@inheritDoc}
     * <p>
     * Sends a POST request to Stripe's payment_intents endpoint with standard authorization headers,
     * including the Idempotency-Key.
     *
     * @param amount the transaction amount in cents/smallest currency unit.
     * @param currency the three-letter ISO currency code.
     * @param idempotencyKey unique key to prevent double charging on retries.
     * @param orderId the ID of the order associated with the payment.
     * @param userId the ID of the user performing the checkout.
     * @return the {@link StripePaymentIntentResult} containing PaymentIntent ID, status, and client secret.
     * @throws PaymentIntegrationException if authentication fails, API returns an error status, or network connection fails.
     */
    @Override
    public StripePaymentIntentResult createPaymentIntent(Long amount, String currency, String idempotencyKey, String orderId, String userId) {
        try {
            String secretKey = stripeProperties.getSecretKey();
            if (secretKey == null || secretKey.isBlank()) {
                throw new PaymentIntegrationException("Stripe secret key is missing");
            }
            if (!secretKey.startsWith("sk_")) {
                throw new PaymentIntegrationException("Stripe secret key is invalid. It must start with sk_");
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(secretKey);
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            headers.add("Idempotency-Key", idempotencyKey);

            MultiValueMap<String, String> payload = new LinkedMultiValueMap<>();
            payload.add("amount", String.valueOf(amount));
            payload.add("currency", currency.toLowerCase());
            payload.add("automatic_payment_methods[enabled]", "true");
            payload.add("metadata[orderId]", orderId);
            payload.add("metadata[userId]", userId);

            log.info("Creating Stripe PaymentIntent: orderId={}, userId={}, amount={}, currency={}", orderId, userId, amount, currency);

            HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(payload, headers);
            Map<String, Object> response = restTemplate.postForObject(STRIPE_PAYMENT_INTENT_API, request, Map.class);

            if (response == null || response.get("id") == null || response.get("client_secret") == null) {
                throw new PaymentIntegrationException("Stripe returned invalid PaymentIntent response");
            }

            return StripePaymentIntentResult.builder()
                    .paymentIntentId(String.valueOf(response.get("id")))
                    .clientSecret(String.valueOf(response.get("client_secret")))
                    .status(String.valueOf(response.get("status")))
                    .build();
        } catch (HttpStatusCodeException ex) {
            String responseBody = ex.getResponseBodyAsString();
            log.error(
                    "Stripe PaymentIntent creation failed with status {}. orderId={}, userId={}, response={}",
                    ex.getStatusCode().value(),
                    orderId,
                    userId,
                    responseBody,
                    ex
            );
            String message = "Stripe API error (" + ex.getStatusCode().value() + ")";
            if (responseBody != null && !responseBody.isBlank()) {
                message += ": " + responseBody;
            }
            throw new PaymentIntegrationException(message, ex);
        } catch (RestClientException ex) {
            log.error("Stripe PaymentIntent creation failed. orderId={}, userId={}, message={}", orderId, userId, ex.getMessage(), ex);
            throw new PaymentIntegrationException("Failed to create Stripe PaymentIntent", ex);
        }
    }
}


