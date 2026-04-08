package org.backend.client.service;


import org.backend.client.dto.request.UpPremiumRequest;
import org.backend.client.dto.response.SubscriptionInfoResponse;
import org.springframework.stereotype.Service;

@Service
public interface SubscriptionService {

    void subscribe(UpPremiumRequest req);
    void unsubscribe();
    SubscriptionInfoResponse getSubscriptionInfo();
}
