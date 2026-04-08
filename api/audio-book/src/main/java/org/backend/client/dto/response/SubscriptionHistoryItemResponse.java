package org.backend.client.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class SubscriptionHistoryItemResponse {
    private String planName;
    private Long price;
    private String timeUnit;
    private LocalDate startDate;
    private String status;
}
