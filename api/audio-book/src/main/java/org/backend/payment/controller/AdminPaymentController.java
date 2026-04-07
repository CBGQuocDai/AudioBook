package org.backend.payment.controller;

import lombok.RequiredArgsConstructor;
import org.backend.common.response.ApiResponse;
import org.backend.payment.dto.response.PaymentDashboardResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.backend.payment.service.PaymentService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/payments")
@PreAuthorize("hasRole('ADMIN')")
public class AdminPaymentController {

    private final PaymentService paymentService;

    @GetMapping("/dashboard")
    public ApiResponse<PaymentDashboardResponse> getDashboard() {
        return ApiResponse.<PaymentDashboardResponse>builder()
                .data(paymentService.getDashboard())
                .build();
    }

    @GetMapping("/logs")
    public ApiResponse<Page<PaymentDetailResponse>> getPaymentLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.<Page<PaymentDetailResponse>>builder()
                .data(paymentService.getPaymentLogs(PageRequest.of(page, size)))
                .build();
    }
}

