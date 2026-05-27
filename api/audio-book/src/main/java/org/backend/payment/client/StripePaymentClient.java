package org.backend.payment.client;

/**
 * Client interface for interacting with Stripe payment processing APIs.
 */
public interface StripePaymentClient {

    /**
     * Creates a new PaymentIntent in Stripe.
     *
     * @param amount the transaction amount in cents/smallest currency unit.
     * @param currency the three-letter ISO currency code.
     * @param idempotencyKey unique key to prevent double charging on retries.
     * @param orderId the ID of the order associated with the payment.
     * @param userId the ID of the user performing the checkout.
     * @return the result containing PaymentIntent details.
     * @throws org.backend.payment.exception.PaymentIntegrationException if Stripe API returns an error.
     */
    StripePaymentIntentResult createPaymentIntent(Long amount, String currency, String idempotencyKey, String orderId, String userId);
}

