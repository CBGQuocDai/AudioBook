package org.backend.client.service;

import org.backend.client.dto.request.CreateCreditPurchaseIntentRequest;
import org.backend.client.dto.request.ConfirmCreditPurchaseRequest;
import org.backend.client.entity.CreditPlan;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface CreditPlanService {
    List<CreditPlan> getPlan();

    CreateStripeIntentResponse createPurchaseIntent(CreateCreditPurchaseIntentRequest request);

    PaymentDetailResponse confirmPurchase(ConfirmCreditPurchaseRequest request);
}
