package org.backend.user.repository;

import jakarta.validation.constraints.Email;
import org.backend.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Database repository operations interface for managing {@link User} entity persistence.
 */
@Repository
public interface UserRepository  extends JpaRepository<User, Long> {

    /**
     * Resolves a user entity associated with the targeted email.
     *
     * @param email lookup email value
     * @return the matching {@link User} entity or null if missing
     */
    User findByEmail(String email);

    /**
     * Asserts if any user exists matching the targeted email.
     *
     * @param email assertion query target
     * @return true if a user already exists with this email, false otherwise
     */
    boolean existsByEmail(String email);

    /**
     * Resolves a user entity matching the targeted email and active status constraints.
     *
     * @param email validated email query parameter
     * @param b active status assertion
     * @return the matching active {@link User} or null
     */
    User findByEmailAndActive(@Email(message = "Email is not valid") String email, boolean b);

    /**
     * Asserts if a user exists with matching email and active status requirements.
     *
     * @param email email criteria
     * @param b active state criteria
     * @return true if a corresponding active user exists
     */
    boolean existsByEmailAndActive(@Email(message = "email is invalid") String email, boolean b);
}
