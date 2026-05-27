package org.backend.client.entity;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.backend.client.enums.Status;
import org.backend.payment.entity.PaymentTransaction;

/**
 * Entity representing a credit transaction where a client purchases credit packages.
 */
@Entity
@Getter
@Setter
public class CreditTransaction {
    /**
     * Primary key identifier for the transaction.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * The client who initiated this transaction.
     */
    @ManyToOne
    @JoinColumn(name = "client_id")
    private Client client;

    /**
     * The status of the credit transaction (PENDING, ACTIVE, CANCELED).
     */
    @Enumerated(EnumType.STRING)
    private Status status;

    /**
     * The credit plan associated with the purchase.
     */
    @ManyToOne
    @JoinColumn(name = "credit_plan_id")
    private CreditPlan creditPlan;

    /**
     * The underlying payment transaction record.
     */
    @OneToOne
    @JoinColumn(name = "payment_id", nullable = false, unique = true)
    private PaymentTransaction paymentTransaction;
}
