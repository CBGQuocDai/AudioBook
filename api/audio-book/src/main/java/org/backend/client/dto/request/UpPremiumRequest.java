package org.backend.client.dto.request;


import lombok.Getter;
import lombok.Setter;

/**
 * Request DTO to upgrade a client's subscription tier to premium.
 */
@Getter
@Setter
public class UpPremiumRequest {

    /**
     * The ID of the subscription plan to upgrade to.
     */
    private Long planId;

    /**
     * The ID of the successful payment transaction.
     */
    private Long paymentId;
}
