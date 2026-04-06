package org.backend.payment.dto.response;

import lombok.Builder;
import lombok.Getter;
import org.backend.payment.enums.PaymentMethod;
import org.backend.payment.enums.PaymentProvider;
import org.backend.payment.enums.PaymentStatus;

@Getter
@Builder
public class CreateStripeIntentResponse {

    private Long paymentId;
    private String paymentCode;
    private PaymentStatus status;
    private PaymentProvider provider;
    private PaymentMethod method;
    private String stripePaymentIntentId;
    private String clientSecret;
    private String message;
}

