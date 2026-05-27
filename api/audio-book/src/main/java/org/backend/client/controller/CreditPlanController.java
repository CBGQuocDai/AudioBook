package org.backend.client.controller;


import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.ConfirmCreditPurchaseRequest;
import org.backend.client.dto.request.CreateCreditPurchaseIntentRequest;
import org.backend.client.entity.CreditPlan;
import org.backend.client.service.CreditPlanService;
import org.backend.common.response.ApiResponse;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller to handle operations related to credit plans and credit purchase flow.
 */
@RestController
@RequestMapping("/credit-plan")
@RequiredArgsConstructor
@Validated
public class CreditPlanController {

    private final CreditPlanService creditPlanService;

    /**
     * Retrieves all available credit purchase plans.
     *
     * @return ApiResponse containing the list of available credit plans.
     */
    @GetMapping
    public ApiResponse<List<CreditPlan>> getPlans() {
        return ApiResponse.<List<CreditPlan>>builder()
                .data(creditPlanService.getPlan())
                .build();
    }

    /**
     * Initiates a credit purchase payment intent with Stripe.
     * Requires active Premium subscription checks inside the service.
     *
     * @param request The purchase intent details (credit plan ID, payment method, idempotency key).
     * @return ApiResponse containing the Stripe client secret.
     */
    @PostMapping("/purchase-intent")
    public ApiResponse<CreateStripeIntentResponse> createPurchaseIntent(
            @Valid @RequestBody CreateCreditPurchaseIntentRequest request
    ) {
        return ApiResponse.<CreateStripeIntentResponse>builder()
                .data(creditPlanService.createPurchaseIntent(request))
                .build();
    }

    /**
     * Confirms the credit purchase once Stripe transaction is completed successfully.
     * Adds the respective credit amount to the client's total balance.
     *
     * @param request The request containing the payment transaction ID.
     * @return ApiResponse signifying successful confirmation.
     */
    @PostMapping("/purchase-confirm")
    public ApiResponse<?> confirmPurchase(
            @Valid @RequestBody ConfirmCreditPurchaseRequest request
    ) {
        creditPlanService.confirmPurchase(request);
        return ApiResponse.builder()
                .build();
    }
}
