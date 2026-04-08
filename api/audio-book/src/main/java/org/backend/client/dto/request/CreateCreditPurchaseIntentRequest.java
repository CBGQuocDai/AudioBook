package org.backend.client.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.backend.payment.enums.PaymentMethod;

@Getter
@Setter
public class CreateCreditPurchaseIntentRequest {

    @NotNull(message = "creditPlanId is required")
    private Long creditPlanId;

    @NotNull(message = "paymentMethod is required")
    private PaymentMethod paymentMethod;

    @NotBlank(message = "idempotencyKey must not be blank")
    private String idempotencyKey;
}