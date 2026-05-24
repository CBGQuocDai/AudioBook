package org.backend.client.entity;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.backend.client.enums.Status;
import org.backend.payment.entity.PaymentTransaction;

@Entity
@Getter
@Setter
public class CreditTransaction {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "client_id")
    private Client client;

    @Enumerated(EnumType.STRING)
    private Status status;

    @ManyToOne
    @JoinColumn(name = "credit_plan_id")
    private CreditPlan creditPlan;

    @OneToOne
    @JoinColumn(name = "payment_id", nullable = false, unique = true)
    private PaymentTransaction paymentTransaction;
}
