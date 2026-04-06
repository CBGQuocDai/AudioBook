package org.backend.payment.client;

public interface StripePaymentClient {

    StripePaymentIntentResult createPaymentIntent(Long amount, String currency, String idempotencyKey, String orderId, String userId);
}

