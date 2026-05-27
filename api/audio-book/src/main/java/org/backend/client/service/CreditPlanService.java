package org.backend.client.service;

import org.backend.client.dto.request.CreateCreditPurchaseIntentRequest;
import org.backend.client.dto.request.ConfirmCreditPurchaseRequest;
import org.backend.client.entity.CreditPlan;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service interface for managing credit purchases and payment intents.
 */
@Service
public interface CreditPlanService {
    /**
     * Retrieves all available credit purchase plans.
     *
     * @return List of credit plans.
     */
    List<CreditPlan> getPlan();

    /**
     * Creates a payment intent for purchasing a credit plan.
     * Returns Stripe credentials needed to complete the client-side transaction.
     *
     * @param request Request containing credit plan ID.
     * @return CreateStripeIntentResponse with payment client secret.
     * @throws RuntimeException if plan not found or processing fails.
     */
    CreateStripeIntentResponse createPurchaseIntent(CreateCreditPurchaseIntentRequest request);

    /**
     * Confirms the credit purchase after successful payment transaction on the payment provider side.
     * Adds the corresponding credit amount to the client's balance.
     *
     * @param request Request containing the payment transaction ID to confirm.
     * @throws RuntimeException if transaction is not found, or is not in SUCCESS status.
     */
    void confirmPurchase(ConfirmCreditPurchaseRequest request);
}
