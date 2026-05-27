package org.backend.client.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/**
 * Request DTO to confirm a pending credit purchase once payment has succeeded.
 */
@Getter
@Setter
public class ConfirmCreditPurchaseRequest {

    /**
     * The database ID of the successful payment transaction record.
     */
    @NotNull(message = "paymentId is required")
    private Long paymentId;
}