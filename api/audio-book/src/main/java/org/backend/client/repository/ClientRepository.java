package org.backend.client.repository;


import io.lettuce.core.dynamic.annotation.Param;
import org.backend.client.entity.Client;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

/**
 * Repository interface for managing Client entities.
 * Extends JPA repository to perform standard database operations.
 */
@Repository
public interface ClientRepository extends JpaRepository<Client, Long> {
    /**
     * Finds a client by their email address.
     *
     * @param email The email to search for.
     * @return The Client entity if found, otherwise null.
     */
    Client findByEmail(String email);

    /**
     * Finds a client by email and their active status.
     *
     * @param email The email to search for.
     * @param b The active status.
     * @return The Client entity if found, otherwise null.
     */
    Client findByEmailAndActive(String email, boolean b);

    /**
     * Checks if a client exists with the given email and active status.
     *
     * @param email The email to check.
     * @param b The active status.
     * @return true if the client exists and matches the active status, otherwise false.
     */
    boolean existsByEmailAndActive(String email, boolean b);

    /**
     * Native SQL query to check if a client has an active subscription.
     * Evaluates expiration date dynamically using starting date (start_at) and plan duration.
     *
     * @param clientId The ID of the client to check.
     * @return 1 if an active valid subscription exists, otherwise 0.
     */
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
