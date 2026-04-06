package org.backend.payment.client;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class StripePaymentIntentResult {

    private final String paymentIntentId;
    private final String clientSecret;
    private final String status;
}

