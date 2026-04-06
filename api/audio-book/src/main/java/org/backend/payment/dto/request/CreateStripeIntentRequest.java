package org.backend.payment.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.backend.payment.enums.PaymentMethod;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateStripeIntentRequest {

    @NotBlank(message = "orderId must not be blank")
    private String orderId;

    @NotBlank(message = "userId must not be blank")
    private String userId;

    @NotNull(message = "amount must not be null")
    @Min(value = 1, message = "amount must be greater than 0")
    private Long amount;

    @NotBlank(message = "currency must not be blank")
    private String currency;

    @NotNull(message = "paymentMethod is required")
    private PaymentMethod paymentMethod;

    @NotBlank(message = "idempotencyKey must not be blank")
    private String idempotencyKey;
}

