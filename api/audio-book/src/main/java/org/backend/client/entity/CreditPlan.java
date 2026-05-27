package org.backend.client.entity;


import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Getter;
import lombok.Setter;

/**
 * Entity representing a plan/package for buying credits.
 */
@Entity
@Getter
@Setter
public class CreditPlan {
    /**
     * The database ID of the credit plan.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * The price of the credit plan in currency units.
     */
    private Long price;

    /**
     * The name of the credit package (e.g., "10 Credits Pack").
     */
    private String name;

    /**
     * The amount of credits provided by this plan.
     */
    private String amount;
}
