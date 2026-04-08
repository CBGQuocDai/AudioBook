package org.backend.client.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.client.dto.response.PlanResponse;
import org.backend.client.entity.Plan;
import org.backend.client.repository.ClientRepository;
import org.backend.client.repository.PlanRepository;
import org.backend.client.service.PlanService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PlanServiceImpl implements PlanService {
    private final PlanRepository planRepository;
    @Override
    public List<PlanResponse> getAllPlans() {
        List<Plan> plans = planRepository.findAll();

        return plans.stream().map(p -> new PlanResponse(p.getId(),p.getPrice(),p.getName(),p.getTimeUnit().name())).toList();
    }
}
