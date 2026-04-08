package org.backend.client.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ConfirmCreditPurchaseRequest {

    @NotNull(message = "paymentId is required")
    private Long paymentId;
}