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

/**
 * DTO representing a request to create a Stripe PaymentIntent.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateStripeIntentRequest {

    /**
     * Unique identifier of the associated order.
     */
    @NotBlank(message = "orderId must not be blank")
    private String orderId;

    /**
     * Unique identifier of the user making the payment.
     */
    @NotBlank(message = "userId must not be blank")
    private String userId;

    /**
     * Payment amount (typically in the smallest currency unit, e.g., cents).
     */
    @NotNull(message = "amount must not be null")
    @Min(value = 1, message = "amount must be greater than 0")
    private Long amount;

    /**
     * Three-letter ISO currency code (e.g., "usd").
     */
    @NotBlank(message = "currency must not be blank")
    private String currency;

    /**
     * Chosen payment method type.
     */
    @NotNull(message = "paymentMethod is required")
    private PaymentMethod paymentMethod;

    /**
     * Unique idempotency key to prevent double charging for the same transaction.
     */
    @NotBlank(message = "idempotencyKey must not be blank")
    private String idempotencyKey;
}

