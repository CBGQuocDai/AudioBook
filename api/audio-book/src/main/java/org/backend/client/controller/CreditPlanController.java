package org.backend.client.controller;


import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.ConfirmCreditPurchaseRequest;
import org.backend.client.dto.request.CreateCreditPurchaseIntentRequest;
import org.backend.client.entity.CreditPlan;
import org.backend.client.service.CreditPlanService;
import org.backend.common.response.ApiResponse;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/credit-plan")
@RequiredArgsConstructor
@Validated
public class CreditPlanController {

    private final CreditPlanService creditPlanService;

    @GetMapping
    public ApiResponse<List<CreditPlan>> getPlans() {
        return ApiResponse.<List<CreditPlan>>builder()
                .data(creditPlanService.getPlan())
                .build();
    }

    @PostMapping("/purchase-intent")
    public ApiResponse<CreateStripeIntentResponse> createPurchaseIntent(
            @Valid @RequestBody CreateCreditPurchaseIntentRequest request
    ) {
        return ApiResponse.<CreateStripeIntentResponse>builder()
                .data(creditPlanService.createPurchaseIntent(request))
                .build();
    }

    @PostMapping("/purchase-confirm")
    public ApiResponse<PaymentDetailResponse> confirmPurchase(
            @Valid @RequestBody ConfirmCreditPurchaseRequest request
    ) {
        return ApiResponse.<PaymentDetailResponse>builder()
                .data(creditPlanService.confirmPurchase(request))
                .build();
    }
}
