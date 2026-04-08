package org.backend.client.controller;


import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.UpPremiumRequest;
import org.backend.client.dto.response.SubscriptionInfoResponse;
import org.backend.client.service.SubscriptionService;
import org.backend.common.response.ApiResponse;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/subscription")
@RequiredArgsConstructor
public class SubscriptionController {
    private final SubscriptionService subscriptionService;

    @GetMapping
    public ApiResponse<SubscriptionInfoResponse> getSubscriptionInfo() {
        return ApiResponse.<SubscriptionInfoResponse>builder()
                .data(subscriptionService.getSubscriptionInfo())
                .build();
    }

    @PostMapping
    public ApiResponse<Void> subscribe(@RequestBody UpPremiumRequest request){
        subscriptionService.subscribe(request);
        return ApiResponse.<Void>builder().build();
    }
    @DeleteMapping
    public ApiResponse<Void> unsubscribe(){
        subscriptionService.unsubscribe();
        return ApiResponse.<Void>builder().build();
    }

}
