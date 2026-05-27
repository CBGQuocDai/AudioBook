package org.backend.payment.service;

import org.backend.payment.dto.request.CreateStripeIntentRequest;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;

public interface PaymentService {

    CreateStripeIntentResponse createStripeIntent(CreateStripeIntentRequest request);

    PaymentDetailResponse getPayment(Long paymentId);

    PaymentDetailResponse updatePaymentFromStripeEvent(String stripePaymentIntentId, String status, String failureReason);
}

