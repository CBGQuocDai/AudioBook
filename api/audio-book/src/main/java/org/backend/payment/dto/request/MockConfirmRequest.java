package org.backend.payment.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.backend.payment.enums.MockConfirmResult;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MockConfirmRequest {

    @NotNull(message = "paymentId is required")
    private Long paymentId;

    @NotNull(message = "result is required")
    private MockConfirmResult result;

    private String failureReason;
}

