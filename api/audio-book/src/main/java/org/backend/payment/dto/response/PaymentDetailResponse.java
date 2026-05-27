package org.backend.payment.dto.response;

import lombok.Builder;
import lombok.Getter;
import org.backend.payment.enums.PaymentMethod;
import org.backend.payment.enums.PaymentProvider;
import org.backend.payment.enums.PaymentStatus;

import java.time.LocalDateTime;

/**
 * DTO containing detailed information about a payment transaction.
 */
@Getter
@Builder
public class PaymentDetailResponse {

    /**
     * Unique internal payment ID.
     */
    private Long paymentId;

    /**
     * Unique internal payment business code.
     */
    private String paymentCode;

    /**
     * Unique ID of the associated order.
     */
    private String orderId;

    /**
     * Unique ID of the user who made the payment.
     */
    private String userId;

    /**
     * Payment provider handling the transaction.
     */
    private PaymentProvider provider;

    /**
     * Payment method chosen.
     */
    private PaymentMethod method;

    /**
     * Total transaction amount.
     */
    private Long amount;

    /**
     * Currency code (e.g. "usd").
     */
    private String currency;

    /**
     * Current status of the payment.
     */
    private PaymentStatus status;

    /**
     * Stripe's unique PaymentIntent identifier.
     */
    private String stripePaymentIntentId;

    /**
     * Unique idempotency key used for the request.
     */
    private String idempotencyKey;

    /**
     * Detail/reason for transaction failure, if applicable.
     */
    private String failureReason;

    /**
     * The timestamp when this record was created.
     */
    private LocalDateTime createdAt;

    /**
     * The timestamp when this record was last updated.
     */
    private LocalDateTime updatedAt;
}
