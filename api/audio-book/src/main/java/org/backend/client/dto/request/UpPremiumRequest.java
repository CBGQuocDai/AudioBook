package org.backend.client.dto.request;


import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpPremiumRequest {

    private Long planId;
    private Long paymentId;
}
