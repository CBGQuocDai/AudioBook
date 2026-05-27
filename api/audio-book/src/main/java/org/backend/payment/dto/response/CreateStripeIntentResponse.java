package org.backend.payment.dto.response;

import lombok.Builder;
import lombok.Getter;
import org.backend.payment.enums.PaymentMethod;
import org.backend.payment.enums.PaymentProvider;
import org.backend.payment.enums.PaymentStatus;

/**
 * DTO representing the response after initiating a Stripe PaymentIntent.
 */
@Getter
@Builder
public class CreateStripeIntentResponse {

    /**
     * Unique internal payment ID.
     */
    private Long paymentId;

    /**
     * Unique internal payment business code.
     */
    private String paymentCode;

    /**
     * Current status of the payment.
     */
    private PaymentStatus status;

    /**
     * Payment provider handling the transaction.
     */
    private PaymentProvider provider;

    /**
     * Payment method chosen.
     */
    private PaymentMethod method;

    /**
     * Stripe's unique PaymentIntent identifier.
     */
    private String stripePaymentIntentId;

    /**
     * Client secret used by frontend SDKs to complete checkout safely.
     */
    private String clientSecret;

    /**
     * Descriptive outcome or status message.
     */
    private String message;
}

