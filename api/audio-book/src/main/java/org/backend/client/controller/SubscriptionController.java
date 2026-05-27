package org.backend.client.controller;


import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.UpPremiumRequest;
import org.backend.client.dto.response.SubscriptionInfoResponse;
import org.backend.client.service.SubscriptionService;
import org.backend.common.response.ApiResponse;
import org.springframework.web.bind.annotation.*;

/**
 * Controller to manage client premium subscriptions.
 */
@RestController
@RequestMapping("/subscription")
@RequiredArgsConstructor
public class SubscriptionController {
    private final SubscriptionService subscriptionService;

    /**
     * Retrieves active subscription details and history for the logged-in client.
     *
     * @return ApiResponse containing the SubscriptionInfoResponse.
     */
    @GetMapping
    public ApiResponse<SubscriptionInfoResponse> getSubscriptionInfo() {
        return ApiResponse.<SubscriptionInfoResponse>builder()
                .data(subscriptionService.getSubscriptionInfo())
                .build();
    }

    /**
     * Upgrades the client's subscription tier using plan & successful payment details.
     *
     * @param request Target plan ID and payment transaction ID.
     * @return ApiResponse with empty payload signifying completion.
     */
    @PostMapping
    public ApiResponse<Void> subscribe(@RequestBody UpPremiumRequest request){
        subscriptionService.subscribe(request);
        return ApiResponse.<Void>builder().build();
    }

    /**
     * Cancels the active premium subscription for the currently logged-in client.
     * Sets subscription status to CANCELED.
     *
     * @return ApiResponse with empty payload signifying successful cancellation.
     */
    @DeleteMapping
    public ApiResponse<Void> unsubscribe(){
        subscriptionService.unsubscribe();
        return ApiResponse.<Void>builder().build();
    }

}
