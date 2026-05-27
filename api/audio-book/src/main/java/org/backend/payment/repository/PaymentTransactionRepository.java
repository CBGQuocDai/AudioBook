package org.backend.payment.repository;

import org.backend.payment.entity.PaymentTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * Repository interface for managing {@link PaymentTransaction} database operations.
 */
public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Long> {

    /**
     * Finds a payment transaction by its idempotency key.
     *
     * @param idempotencyKey the idempotency key of the transaction.
     * @return an {@link Optional} containing the found payment transaction, or empty.
     */
    Optional<PaymentTransaction> findByIdempotencyKey(String idempotencyKey);

    /**
     * Finds a payment transaction by its Stripe PaymentIntent identifier.
     *
     * @param stripePaymentIntentId the Stripe PaymentIntent ID.
     * @return an {@link Optional} containing the found payment transaction, or empty.
     */
    Optional<PaymentTransaction> findByStripePaymentIntentId(String stripePaymentIntentId);

    /**
     * Retrieves all payment transactions paginated, ordered by creation date descending.
     *
     * @param pageable pagination details.
     * @return a page of payment transactions.
     */
    Page<PaymentTransaction> findAllByOrderByCreatedAtDesc(Pageable pageable);
}

