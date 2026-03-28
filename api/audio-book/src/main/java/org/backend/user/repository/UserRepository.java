package org.backend.user.repository;

import jakarta.validation.constraints.Email;
import org.backend.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository  extends JpaRepository<User, Long> {

    User findByEmail(String email);

    boolean existsByEmail(String email);

    @Query("""
            select u from User u
            where lower(u.name) like lower(concat('%', :keyword, '%'))
               or lower(u.email) like lower(concat('%', :keyword, '%'))
            """)
    Page<User> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);

    User findByEmailAndActive(@Email(message = "Email is not valid") String email, boolean b);

    boolean existsByEmailAndActive(@Email(message = "email is invalid") String email, boolean b);
}
