package org.backend.client.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

/**
 * Response DTO returning complete subscription information including status and history.
 */
@Getter
@Builder
public class SubscriptionInfoResponse {
    /**
     * The name of the currently active/selected subscription plan.
     */
    private String planName;

    /**
     * The status of the current subscription (e.g., ACTIVE, CANCELED).
     */
    private String status;

    /**
     * The calculated next billing or expiration date.
     */
    private LocalDate nextBillingDate;

    /**
     * The billing price of the active plan.
     */
    private Long price;

    /**
     * The billing cycle unit (e.g., MONTHS, YEARS).
     */
    private String timeUnit;

    /**
     * A complete list of past subscription transactions/history.
     */
    private List<SubscriptionHistoryItemResponse> billingHistory;
}
