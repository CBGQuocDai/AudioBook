package org.backend.client.repository;


import org.backend.client.entity.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository interface for managing Subscription entities.
 */
@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {
    /**
     * Native SQL query to find the latest active and valid subscription for a client.
     * Uses CASE WHEN statement to dynamically calculate expiration date based on the plan's time_unit (DAYS, MONTHS, YEARS).
     * Filters for active status and checks that the subscription has not expired relative to the current time.
     *
     * @param clientId The ID of the client.
     * @return An Optional containing the latest active valid subscription, or empty if none matches.
     */
    @Query(value = """
    SELECT s.*
    FROM subscription s
    JOIN plan p ON s.plan_id = p.id
    WHERE s.client_id = :clientId
      AND s.status = 'ACTIVE'
      AND (
        CASE
          WHEN p.time_unit = 'DAYS'
            THEN DATE_ADD(s.start_at, INTERVAL 1 DAY)
          WHEN p.time_unit = 'MONTHS'
            THEN DATE_ADD(s.start_at, INTERVAL 1 MONTH)
          WHEN p.time_unit = 'YEARS'
            THEN DATE_ADD(s.start_at, INTERVAL 1 YEAR)
        END
      ) > NOW()
    ORDER BY s.start_at DESC
    LIMIT 1
""", nativeQuery = true)
    Optional<Subscription> findLatestActiveValidSubscription(Long clientId);

    /**
     * Native SQL query to fetch the subscription history for a given client ordered by start time descending.
     *
     * @param clientId The ID of the client.
     * @return A list of subscriptions associated with the client.
     */
    @Query(value = """
    SELECT s.*
    FROM subscription s
    WHERE s.client_id = :clientId
    ORDER BY s.start_at DESC
    """, nativeQuery = true)
    List<Subscription> findHistoryByClientId(Long clientId);

    /**
     * Finds a subscription by its associated payment transaction ID.
     *
     * @param paymentTransactionId The ID of the payment transaction.
     * @return An Optional containing the found Subscription, or empty if not found.
     */
    Optional<Subscription> findByPaymentTransactionId(Long paymentTransactionId);
}
