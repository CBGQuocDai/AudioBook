package org.backend.payment.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldNameConstants;
import org.backend.common.entity.AbstractAuditingEntity;
import org.backend.payment.enums.PaymentMethod;
import org.backend.payment.enums.PaymentProvider;
import org.backend.payment.enums.PaymentStatus;

@Entity(name = "PaymentTransaction")
@Table(
    name = "payment_transaction",
        uniqueConstraints = {
        @UniqueConstraint(name = "uk_payment_transaction_payment_code", columnNames = "payment_code"),
        @UniqueConstraint(name = "uk_payment_transaction_idempotency_key", columnNames = "idempotency_key")
        }
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldNameConstants
public class PaymentTransaction extends AbstractAuditingEntity<Long> {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false, updatable = false)
    private Long id;

    @Column(name = "payment_code", nullable = false, unique = true, length = 64)
    private String paymentCode;

    @Column(name = "order_id", nullable = false, length = 128)
    private String orderId;

    @Column(name = "user_id", nullable = false, length = 128)
    private String userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "provider", nullable = false, length = 20)
    private PaymentProvider provider;

    @Enumerated(EnumType.STRING)
    @Column(name = "method", nullable = false, length = 20)
    private PaymentMethod method;

    @Column(name = "amount", nullable = false)
    private Long amount;

    @Column(name = "currency", nullable = false, length = 10)
    private String currency;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private PaymentStatus status;

    @Column(name = "stripe_payment_intent_id", length = 128)
    private String stripePaymentIntentId;

    @Column(name = "stripe_client_secret", length = 255)
    private String stripeClientSecret;

    @Column(name = "request_token", columnDefinition = "TEXT")
    private String requestToken;

    @Column(name = "idempotency_key", nullable = false, unique = true, length = 128)
    private String idempotencyKey;

    @Column(name = "failure_reason", length = 500)
    private String failureReason;
}

