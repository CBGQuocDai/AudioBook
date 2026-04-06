package org.backend.payment.dto.response;

import lombok.Builder;
import lombok.Getter;
import org.backend.payment.enums.PaymentStatus;

@Getter
@Builder
public class MockConfirmResponse {

    private Long paymentId;
    private PaymentStatus status;
    private String message;
}

