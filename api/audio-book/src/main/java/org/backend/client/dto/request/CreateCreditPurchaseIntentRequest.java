package org.backend.client.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.backend.payment.enums.PaymentMethod;

/**
 * Request DTO to initiate a payment intent for credit purchases.
 */
@Getter
@Setter
public class CreateCreditPurchaseIntentRequest {

    /**
     * The ID of the credit plan being purchased.
     */
    @NotNull(message = "creditPlanId is required")
    private Long creditPlanId;

    /**
     * The desired payment method (e.g., Stripe, etc.).
     */
    @NotNull(message = "paymentMethod is required")
    private PaymentMethod paymentMethod;

    /**
     * Idempotency key to prevent double charging on API retries.
     */
    @NotBlank(message = "idempotencyKey must not be blank")
    private String idempotencyKey;
}