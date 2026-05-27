package org.backend.client.repository;


import org.backend.client.entity.CreditPlan;
import org.backend.client.entity.CreditTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository interface for managing CreditTransaction entities.
 */
@Repository
public interface CreditTransactionRepository extends JpaRepository<CreditTransaction, Long> {

    /**
     * Finds a credit transaction by its associated payment transaction ID.
     *
     * @param paymentTransactionId The ID of the payment transaction.
     * @return An Optional containing the found CreditTransaction, or empty if not found.
     */
	Optional<CreditTransaction> findByPaymentTransactionId(Long paymentTransactionId);

}
