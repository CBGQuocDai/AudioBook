package org.backend.client.service;


import org.backend.client.dto.request.UpPremiumRequest;
import org.backend.client.dto.response.SubscriptionInfoResponse;
import org.springframework.stereotype.Service;

/**
 * Service interface for managing client Subscriptions (upgrading, canceling, and fetching info).
 */
@Service
public interface SubscriptionService {

    /**
     * Initiates or confirms a subscription upgrade to premium.
     * Uses payment transaction references to link subscription records.
     *
     * @param req The request containing premium plan and payment details.
     * @throws RuntimeException if validation or subscription setup fails.
     */
    void subscribe(UpPremiumRequest req);

    /**
     * Unsubscribes/cancels the active subscription of the currently authenticated client.
     *
     * @throws RuntimeException if no active subscription is found or cancellation fails.
     */
    void unsubscribe();

    /**
     * Retrieves subscription information (status, active plan details, expiration date, history)
     * for the currently authenticated client.
     *
     * @return SubscriptionInfoResponse containing details of the subscription.
     */
    SubscriptionInfoResponse getSubscriptionInfo();
}
