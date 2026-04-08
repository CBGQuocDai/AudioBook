package org.backend.client.repository;


import org.backend.client.entity.CreditPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CreditPlanRepository extends JpaRepository<CreditPlan, Long> {

}
