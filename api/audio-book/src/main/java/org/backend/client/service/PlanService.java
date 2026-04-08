package org.backend.client.service;

import org.backend.client.dto.response.PlanResponse;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface PlanService {
    List<PlanResponse> getAllPlans();

}
