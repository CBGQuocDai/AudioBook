package org.backend.client.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

/**
 * Response DTO representing an item in the client's subscription billing history.
 */
@Getter
@Builder
public class SubscriptionHistoryItemResponse {
    /**
     * Name of the subscription plan.
     */
    private String planName;

    /**
     * Cost of the subscription.
     */
    private Long price;

    /**
     * Plan duration time unit (e.g., MONTHS, YEARS).
     */
    private String timeUnit;

    /**
     * Activation start date.
     */
    private LocalDate startDate;

    /**
     * Status of subscription at that point (ACTIVE, CANCELED).
     */
    private String status;
}
