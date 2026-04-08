package org.backend.client.repository;


import io.lettuce.core.dynamic.annotation.Param;
import org.backend.client.entity.Client;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface ClientRepository extends JpaRepository<Client, Long> {
    Client findByEmail(String email);

    Client findByEmailAndActive(String email, boolean b);

    boolean existsByEmailAndActive(String email, boolean b);

    @Query(value = """
    SELECT EXISTS (
        SELECT 1
        FROM subscription s
        JOIN plan p ON s.plan_id = p.id
        WHERE s.client_id = :clientId
          AND s.status != 'PENDING'
          AND (
            CASE 
              WHEN p.time_unit = 'MONTHS'
                THEN DATE_ADD(s.start_at, INTERVAL 1 MONTH)
              WHEN p.time_unit = 'YEARS'
                THEN DATE_ADD(s.start_at, INTERVAL 1 YEAR)
            END
          ) > NOW()
    )
""", nativeQuery = true)
    Integer isSubscriptionActiveRaw(Long clientId);
}
