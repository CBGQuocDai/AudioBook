package org.backend.client.repository;


import org.backend.client.entity.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {
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

    @Query(value = """
    SELECT s.*
    FROM subscription s
    WHERE s.client_id = :clientId
    ORDER BY s.start_at DESC
    """, nativeQuery = true)
    List<Subscription> findHistoryByClientId(Long clientId);
}
