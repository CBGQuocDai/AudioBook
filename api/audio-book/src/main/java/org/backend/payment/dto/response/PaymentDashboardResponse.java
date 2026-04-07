package org.backend.payment.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PaymentDashboardResponse {
    private long totalDepositedAmount;
    private long successfulTransactionCount;
    private List<PaymentCurrencySummaryResponse> currencySummaries;
}

