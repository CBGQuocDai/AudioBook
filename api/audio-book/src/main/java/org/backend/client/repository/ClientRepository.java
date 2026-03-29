package org.backend.client.repository;


import org.backend.client.entity.Client;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ClientRepository extends JpaRepository<Client, Long> {
    Client findByEmail(String email);

    Client findByEmailAndActive(String email, boolean b);

    boolean existsByEmailAndActive(String email, boolean b);
}
