package org.backend.client.repository;


import org.backend.client.entity.CreditPlan;
import org.backend.client.entity.CreditTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CreditTransactionRepository extends JpaRepository<CreditTransaction, Long> {

	Optional<CreditTransaction> findByPaymentTransactionId(Long paymentTransactionId);

}
