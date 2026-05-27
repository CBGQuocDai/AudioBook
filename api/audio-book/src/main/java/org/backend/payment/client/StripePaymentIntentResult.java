package org.backend.payment.client;

import lombok.Builder;
import lombok.Getter;

/**
 * Holds the raw outcome returned from a Stripe PaymentIntent api operation.
 */
@Getter
@Builder
public class StripePaymentIntentResult {

    /**
     * Unique Stripe PaymentIntent identifier.
     */
    private final String paymentIntentId;

    /**
     * Client secret associated with the Stripe PaymentIntent.
     */
    private final String clientSecret;

    /**
     * Raw status of the PaymentIntent as returned by Stripe (e.g. "requires_payment_method", "succeeded").
     */
    private final String status;
}

