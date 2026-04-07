package org.backend.payment.repository;

import org.backend.payment.dto.response.PaymentCurrencySummaryResponse;
import org.backend.payment.entity.PaymentTransaction;
import org.backend.payment.enums.PaymentStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.List;

public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Long> {

    Optional<PaymentTransaction> findByIdempotencyKey(String idempotencyKey);

    Optional<PaymentTransaction> findByStripePaymentIntentId(String stripePaymentIntentId);

    long countByStatus(PaymentStatus status);

    @Query("""
    select coalesce(sum(p.amount), 0)
    from PaymentTransaction p
    where p.status = org.backend.payment.enums.PaymentStatus.SUCCESS
    """)
    long sumSuccessfulAmount();

    @Query("""
    select new org.backend.payment.dto.response.PaymentCurrencySummaryResponse(
        p.currency,
        coalesce(sum(p.amount), 0),
        count(p)
    )
    from PaymentTransaction p
    where p.status = org.backend.payment.enums.PaymentStatus.SUCCESS
    group by p.currency
    order by sum(p.amount) desc, p.currency asc
    """)
    List<PaymentCurrencySummaryResponse> findSuccessfulCurrencySummaries();

    Page<PaymentTransaction> findAllByOrderByCreatedAtDesc(Pageable pageable);
}

