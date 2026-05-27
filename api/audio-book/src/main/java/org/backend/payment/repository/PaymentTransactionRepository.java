package org.backend.payment.repository;

import org.backend.payment.entity.PaymentTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Long> {

    Optional<PaymentTransaction> findByIdempotencyKey(String idempotencyKey);

    Optional<PaymentTransaction> findByStripePaymentIntentId(String stripePaymentIntentId);

    Page<PaymentTransaction> findAllByOrderByCreatedAtDesc(Pageable pageable);
}

