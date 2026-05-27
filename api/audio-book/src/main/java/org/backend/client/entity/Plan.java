package org.backend.client.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.backend.client.enums.TimeUnit;


/**
 * Entity representing a subscription plan (e.g., Premium Monthly/Yearly).
 */
@Entity
@Getter
@Setter
public class Plan {

    /**
     * The database ID of the plan.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    /**
     * The price of the plan in currency units.
     */
    private Long price;

    /**
     * The name of the subscription plan (e.g., "Premium Month Plan").
     */
    private String name;

    /**
     * The time unit for duration of the subscription (e.g., MONTHS, YEARS).
     */
    @Enumerated(EnumType.STRING)
    private TimeUnit timeUnit;
}
