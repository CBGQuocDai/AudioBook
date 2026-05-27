package org.backend.user.repository;

import jakarta.validation.constraints.Email;
import org.backend.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository  extends JpaRepository<User, Long> {

    User findByEmail(String email);

    boolean existsByEmail(String email);

    User findByEmailAndActive(@Email(message = "Email is not valid") String email, boolean b);

    boolean existsByEmailAndActive(@Email(message = "email is invalid") String email, boolean b);
}
