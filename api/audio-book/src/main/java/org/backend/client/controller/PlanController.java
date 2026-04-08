package org.backend.client.controller;


import lombok.RequiredArgsConstructor;
import org.backend.client.dto.response.PlanResponse;
import org.backend.client.service.PlanService;
import org.backend.common.response.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/plans")
@RequiredArgsConstructor
public class PlanController {

    private final PlanService planService;
    @GetMapping
    public ApiResponse<List<PlanResponse>> getPlans() {
        return ApiResponse.<List<PlanResponse>>builder()
                .data(planService.getAllPlans())
                .build();
    }
}
