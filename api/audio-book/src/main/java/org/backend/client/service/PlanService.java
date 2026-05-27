package org.backend.client.service;

import org.backend.client.dto.response.PlanResponse;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service interface for managing Subscription Plans.
 */
@Service
public interface PlanService {
    /**
     * Retrieves all available subscription plans.
     *
     * @return A list of PlanResponse DTOs containing subscription plan information.
     */
    List<PlanResponse> getAllPlans();

}
