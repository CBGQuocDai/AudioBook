package org.backend.client.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

/**
 * Response DTO returning subscription plan characteristics.
 */
@Getter
@Setter
@AllArgsConstructor
public class PlanResponse {
    /**
     * The identifier of the subscription plan.
     */
    private Long id;

    /**
     * The cost associated with purchasing this subscription plan.
     */
    private Long price;

    /**
     * The descriptive name of the subscription plan.
     */
    private String name;

    /**
     * The billing unit (MONTHS, YEARS).
     */
    private String timeUnit;
}
