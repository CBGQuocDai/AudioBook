package org.backend.payment.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.common.response.ApiResponse;
import org.backend.payment.dto.request.CreateStripeIntentRequest;
import org.backend.payment.dto.request.MockConfirmRequest;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.MockConfirmResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.backend.payment.service.PaymentService;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/payments")
@Validated
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping("/stripe/create-intent")
    public ApiResponse<CreateStripeIntentResponse> createStripeIntent(@Valid @RequestBody CreateStripeIntentRequest request) {
        return ApiResponse.<CreateStripeIntentResponse>builder()
                .data(paymentService.createStripeIntent(request))
                .build();
    }

    @PostMapping("/stripe/mock-confirm")
    public ApiResponse<MockConfirmResponse> mockConfirm(@Valid @RequestBody MockConfirmRequest request) {
        return ApiResponse.<MockConfirmResponse>builder()
                .data(paymentService.mockConfirm(request))
                .build();
    }

    @GetMapping("/{paymentId}")
    public ApiResponse<PaymentDetailResponse> getPayment(@PathVariable Long paymentId) {
        return ApiResponse.<PaymentDetailResponse>builder()
                .data(paymentService.getPayment(paymentId))
                .build();
    }
}

