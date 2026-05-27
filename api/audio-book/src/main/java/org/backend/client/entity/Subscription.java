package org.backend.client.entity;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.backend.client.enums.Status;
import org.backend.payment.entity.PaymentTransaction;

import java.time.LocalDate;

/**
 * Entity representing a Subscription for a client to a specific plan.
 */
@Entity
@Getter
@Setter
public class Subscription {

    /**
     * Unique identifier for the subscription.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * The start date of the subscription.
     */
    private LocalDate startAt;

    /**
     * The status of the subscription (e.g., PENDING, ACTIVE, CANCELED).
     */
    @Enumerated(EnumType.STRING)
    private Status status;

    /**
     * The client who owns the subscription.
     */
    @ManyToOne
    @JoinColumn(name= "client_id")
    private Client client;

    /**
     * The subscription plan associated with this subscription.
     */
    @ManyToOne
    @JoinColumn(name="plan_id")
    private Plan plan;

    /**
     * The payment transaction that paid for this subscription.
     */
    @OneToOne
    @JoinColumn(name = "payment_transaction_id", unique = true)
    private PaymentTransaction paymentTransaction;
}
