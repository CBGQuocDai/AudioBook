package org.backend.payment.service.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.payment.client.StripePaymentClient;
import org.backend.payment.client.StripePaymentIntentResult;
import org.backend.payment.dto.request.CreateStripeIntentRequest;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.backend.payment.entity.PaymentTransaction;
import org.backend.payment.enums.PaymentProvider;
import org.backend.payment.enums.PaymentStatus;
import org.backend.payment.exception.BadRequestException;
import org.backend.payment.exception.ResourceNotFoundException;
import org.backend.payment.repository.PaymentTransactionRepository;
import org.backend.payment.service.PaymentService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

/**
 * Production implementation of {@link PaymentService}.
 * Handles payment intent creation, validation, transaction state machine updates, and Stripe webhook synchronization.
 * Employs optimistic locking retry mechanism to mitigate concurrent updates during webhook processing.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentServiceImpl implements PaymentService {

    /**
     * Database transaction repository.
     */
    private final PaymentTransactionRepository paymentTransactionRepository;

    /**
     * Client interface communicating directly with Stripe REST API.
     */
    private final StripePaymentClient stripePaymentClient;

    /**
     * {@inheritDoc}
     * <p>
     * Implements strict idempotency checking by checking if the normalized key exists in db first.
     * If not found, calls Stripe to register a new PaymentIntent and persists the state locally.
     *
     * @param request the checkout details request.
     * @return the created/existing payment intent details response.
     * @throws BadRequestException if the request contains validation failures.
     * @throws org.backend.payment.exception.PaymentIntegrationException if Stripe integration failures occur.
     */
    @Override
    @Transactional
    public CreateStripeIntentResponse createStripeIntent(CreateStripeIntentRequest request) {
        String normalizedIdempotencyKey = request.getIdempotencyKey().trim();

        PaymentTransaction existing = paymentTransactionRepository.findByIdempotencyKey(normalizedIdempotencyKey).orElse(null);
        if (existing != null) {
            log.info("Idempotency key exists. Returning existing payment: idempotencyKey={}, paymentId={}", normalizedIdempotencyKey, existing.getId());
            return mapCreateIntentResponse(existing, "PaymentIntent already exists for idempotencyKey");
        }

        String normalizedCurrency = request.getCurrency().trim().toLowerCase(Locale.ROOT);

        StripePaymentIntentResult stripeIntent = stripePaymentClient.createPaymentIntent(
                request.getAmount(),
                normalizedCurrency,
                normalizedIdempotencyKey,
                request.getOrderId().trim(),
                request.getUserId().trim()
        );

        PaymentTransaction payment = PaymentTransaction.builder()
                .paymentCode(generatePaymentCode())
                .orderId(request.getOrderId().trim())
                .userId(request.getUserId().trim())
                .provider(PaymentProvider.STRIPE)
                .method(request.getPaymentMethod())
                .amount(request.getAmount())
                .currency(normalizedCurrency)
                .status(PaymentStatus.PENDING)
                .stripePaymentIntentId(stripeIntent.getPaymentIntentId())
                .stripeClientSecret(stripeIntent.getClientSecret())
                .idempotencyKey(normalizedIdempotencyKey)
                .build();

        PaymentTransaction saved = paymentTransactionRepository.saveAndFlush(payment);
        log.info("Stripe PaymentIntent created and persisted. paymentId={}, paymentIntentId={}", saved.getId(), saved.getStripePaymentIntentId());

        return mapCreateIntentResponse(saved, "PaymentIntent created successfully");
    }

    /**
     * {@inheritDoc}
     *
     * @param paymentId the unique database payment transaction ID.
     * @return payment detail response.
     * @throws ResourceNotFoundException if the transaction does not exist.
     */
    @Override
    @Transactional(readOnly = true)
    public PaymentDetailResponse getPayment(Long paymentId) {
        PaymentTransaction payment = paymentTransactionRepository.findById(paymentId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found: " + paymentId));

        return PaymentDetailResponse.builder()
                .paymentId(payment.getId())
                .paymentCode(payment.getPaymentCode())
                .orderId(payment.getOrderId())
                .userId(payment.getUserId())
                .provider(payment.getProvider())
                .method(payment.getMethod())
                .amount(payment.getAmount())
                .currency(payment.getCurrency())
                .status(payment.getStatus())
                .stripePaymentIntentId(payment.getStripePaymentIntentId())
                .idempotencyKey(payment.getIdempotencyKey())
                .failureReason(payment.getFailureReason())
                .createdAt(payment.getCreatedAt())
                .updatedAt(payment.getLastModifiedAt())
                .build();
    }

    /**
     * Maps database model to Stripe creation response.
     *
     * @param payment the transaction entity.
     * @param message custom information message.
     * @return response DTO.
     */
    private CreateStripeIntentResponse mapCreateIntentResponse(PaymentTransaction payment, String message) {
        return CreateStripeIntentResponse.builder()
                .paymentId(payment.getId())
                .paymentCode(payment.getPaymentCode())
                .status(payment.getStatus())
                .provider(payment.getProvider())
                .method(payment.getMethod())
                .stripePaymentIntentId(payment.getStripePaymentIntentId())
                .clientSecret(payment.getStripeClientSecret())
                .message(message)
                .build();
    }

    /**
     * {@inheritDoc}
     * <p>
     * Converts Stripe webhook event codes and executes state synchronization using retry pattern.
     *
     * @param stripePaymentIntentId Stripe PaymentIntent identifier.
     * @param status the updated payment status string from Stripe.
     * @param failureReason explanation of the failure, if applicable.
     * @return the updated transaction details.
     * @throws BadRequestException if the status is unrecognized or empty.
     * @throws ResourceNotFoundException if the payment intent ID is not registered locally.
     */
    @Override
    @Transactional
    public PaymentDetailResponse updatePaymentFromStripeEvent(String stripePaymentIntentId, String status, String failureReason) {
        PaymentStatus targetStatus = mapStripeStatusToPaymentStatus(status);
        String normalizedReason = normalizeFailureReason(failureReason);
        return retryUpdatePaymentFromStripeEvent(stripePaymentIntentId, targetStatus, normalizedReason);
    }

    /**
     * Retries updating payment status up to 3 times to handle optimistic locking conflicts.
     *
     * @param stripePaymentIntentId Stripe PaymentIntent identifier.
     * @param targetStatus the desired database PaymentStatus state.
     * @param normalizedReason sanitized failure description.
     * @return the updated transaction details.
     * @throws ObjectOptimisticLockingFailureException if state was updated concurrently after 3 retry attempts.
     */
    private PaymentDetailResponse retryUpdatePaymentFromStripeEvent(String stripePaymentIntentId,
                                                                     PaymentStatus targetStatus,
                                                                     String normalizedReason) {
        int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                PaymentTransaction payment = loadPaymentByStripeIntent(stripePaymentIntentId);

                if (isAlreadyInTargetState(payment, targetStatus, normalizedReason)) {
                    log.info("Webhook event is idempotent. Keeping current state. paymentId={}, stripePaymentIntentId={}, status={}",
                            payment.getId(), stripePaymentIntentId, targetStatus);
                    return mapPaymentDetailResponse(payment);
                }

                applyTargetStatus(payment, targetStatus, normalizedReason);
                PaymentTransaction updated = paymentTransactionRepository.saveAndFlush(payment);
                log.info("Payment updated from Stripe webhook event. paymentId={}, stripePaymentIntentId={}, status={}",
                        updated.getId(), stripePaymentIntentId, targetStatus);
                return mapPaymentDetailResponse(updated);
            } catch (ObjectOptimisticLockingFailureException ex) {
                log.warn("Optimistic lock while updating payment from webhook (attempt {}/{}). stripePaymentIntentId={}",
                        attempt, maxAttempts, stripePaymentIntentId);
                if (attempt == maxAttempts) {
                    throw ex;
                }
            }
        }

        throw new BadRequestException("Could not update payment from webhook after retries");
    }

    /**
     * Loads a payment transaction from database by its Stripe PaymentIntent identifier.
     *
     * @param stripePaymentIntentId the Stripe PaymentIntent ID.
     * @return the transaction record.
     * @throws ResourceNotFoundException if the payment ID is not found.
     */
    private PaymentTransaction loadPaymentByStripeIntent(String stripePaymentIntentId) {
        return paymentTransactionRepository.findByStripePaymentIntentId(stripePaymentIntentId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found for stripe payment intent: " + stripePaymentIntentId));
    }

    /**
     * Checks if the transaction has already achieved the target status.
     * Used for webhook idempotency to avoid redundant updates.
     *
     * @param payment the current transaction.
     * @param targetStatus the desired PaymentStatus.
     * @param normalizedReason explanation for failures.
     * @return true if already in that state.
     */
    private boolean isAlreadyInTargetState(PaymentTransaction payment, PaymentStatus targetStatus, String normalizedReason) {
        boolean alreadyInTargetState = payment.getStatus() == targetStatus;
        if (targetStatus == PaymentStatus.FAILED) {
            return alreadyInTargetState && Objects.equals(payment.getFailureReason(), normalizedReason);
        }
        return alreadyInTargetState;
    }

    /**
     * Updates the status and logs failure details if the target status is FAILED.
     *
     * @param payment the transaction entity.
     * @param targetStatus the updated PaymentStatus.
     * @param normalizedReason detail/reason for failures.
     */
    private void applyTargetStatus(PaymentTransaction payment, PaymentStatus targetStatus, String normalizedReason) {
        payment.setStatus(targetStatus);
        if (targetStatus == PaymentStatus.FAILED) {
            payment.setFailureReason((normalizedReason == null || normalizedReason.isBlank()) ? "Payment failed" : normalizedReason);
        } else if (targetStatus == PaymentStatus.SUCCESS) {
            payment.setFailureReason(null);
        }
    }

    /**
     * Helper to trim whitespace from failure descriptions.
     *
     * @param failureReason input failure reason.
     * @return trimmed string or null.
     */
    private String normalizeFailureReason(String failureReason) {
        return failureReason == null ? null : failureReason.trim();
    }

    /**
     * Maps database model to PaymentDetailResponse DTO.
     *
     * @param payment the transaction entity.
     * @return payment detail response.
     */
    private PaymentDetailResponse mapPaymentDetailResponse(PaymentTransaction payment) {
        return PaymentDetailResponse.builder()
                .paymentId(payment.getId())
                .paymentCode(payment.getPaymentCode())
                .orderId(payment.getOrderId())
                .userId(payment.getUserId())
                .provider(payment.getProvider())
                .method(payment.getMethod())
                .amount(payment.getAmount())
                .currency(payment.getCurrency())
                .status(payment.getStatus())
                .stripePaymentIntentId(payment.getStripePaymentIntentId())
                .idempotencyKey(payment.getIdempotencyKey())
                .failureReason(payment.getFailureReason())
                .createdAt(payment.getCreatedAt())
                .updatedAt(payment.getLastModifiedAt())
                .build();
    }

    /**
     * Converts a Stripe webhook event type string to domestic {@link PaymentStatus}.
     *
     * @param stripeStatus the webhook event string (e.g. "payment_intent.succeeded").
     * @return corresponding {@link PaymentStatus}.
     * @throws BadRequestException if the status is unknown or empty.
     */
    private PaymentStatus mapStripeStatusToPaymentStatus(String stripeStatus) {
        if (stripeStatus == null || stripeStatus.isBlank()) {
            throw new BadRequestException("Stripe status cannot be null or empty");
        }

        return switch (stripeStatus) {
            case "payment_intent.succeeded" -> PaymentStatus.SUCCESS;
            case "payment_intent.payment_failed" -> PaymentStatus.FAILED;
            default -> throw new BadRequestException("Unknown Stripe event status: " + stripeStatus);
        };
    }

    /**
     * Generates a unique business payment reference identifier.
     *
     * @return generated payment reference string.
     */
    private String generatePaymentCode() {
        return "PAY_" + UUID.randomUUID().toString().replace("-", "").substring(0, 16).toUpperCase(Locale.ROOT);
    }

}