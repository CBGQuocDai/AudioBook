package org.backend.payment.dto.response;

import lombok.Builder;
import lombok.Getter;
import org.backend.payment.enums.PaymentMethod;
import org.backend.payment.enums.PaymentProvider;
import org.backend.payment.enums.PaymentStatus;

import java.time.LocalDateTime;

@Getter
@Builder
public class PaymentDetailResponse {

    private Long paymentId;
    private String paymentCode;
    private String orderId;
    private String userId;
    private PaymentProvider provider;
    private PaymentMethod method;
    private Long amount;
    private String currency;
    private PaymentStatus status;
    private String stripePaymentIntentId;
    private String idempotencyKey;
    private String failureReason;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
