package org.backend.payment.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.common.response.ApiResponse;
import org.backend.payment.dto.request.CreateStripeIntentRequest;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.backend.payment.service.PaymentService;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for handling user-initiated payment actions.
 * Exposes endpoints to create Stripe intents and query transaction statuses.
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/payments")
@Validated
public class PaymentController {

    /**
     * Service processing core payment domain logic.
     */
    private final PaymentService paymentService;

    /**
     * Endpoint to create a Stripe payment intent.
     *
     * @param request body containing order ID, amount, currency, payment method, and idempotency key.
     * @return an {@link ApiResponse} wrapping the Stripe intent creation details.
     */
    @PostMapping("/stripe/create-intent")
    public ApiResponse<CreateStripeIntentResponse> createStripeIntent(@Valid @RequestBody CreateStripeIntentRequest request) {
        return ApiResponse.<CreateStripeIntentResponse>builder()
                .data(paymentService.createStripeIntent(request))
                .build();
    }

    /**
     * Endpoint to retrieve details of a specific payment transaction.
     *
     * @param paymentId the internal database payment ID.
     * @return an {@link ApiResponse} wrapping the payment details.
     */
    @GetMapping("/{paymentId}")
    public ApiResponse<PaymentDetailResponse> getPayment(@PathVariable Long paymentId) {
        return ApiResponse.<PaymentDetailResponse>builder()
                .data(paymentService.getPayment(paymentId))
                .build();
    }
}

