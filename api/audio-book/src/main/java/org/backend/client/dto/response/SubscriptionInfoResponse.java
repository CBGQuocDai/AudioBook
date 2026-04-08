package org.backend.client.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class SubscriptionInfoResponse {
    private String planName;
    private String status;
    private LocalDate nextBillingDate;
    private Long price;
    private String timeUnit;
    private List<SubscriptionHistoryItemResponse> billingHistory;
}
