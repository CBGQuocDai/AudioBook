package org.backend.payment.service;

import org.backend.payment.dto.request.CreateStripeIntentRequest;
import org.backend.payment.dto.request.MockConfirmRequest;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDashboardResponse;
import org.backend.payment.dto.response.MockConfirmResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface PaymentService {

    CreateStripeIntentResponse createStripeIntent(CreateStripeIntentRequest request);

    MockConfirmResponse mockConfirm(MockConfirmRequest request);

    PaymentDetailResponse getPayment(Long paymentId);

    PaymentDashboardResponse getDashboard();

    Page<PaymentDetailResponse> getPaymentLogs(Pageable pageable);

    PaymentDetailResponse updatePaymentFromStripeEvent(String stripePaymentIntentId, String status, String failureReason);
}

