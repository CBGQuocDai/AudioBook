package org.backend.payment.config;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "payment.stripe")
public class StripeProperties {

    @NotBlank
    private String secretKey;

    @NotBlank
    private String publishableKey;

    private String webhookSecret;

    private String successUrl;

    private String cancelUrl;
}

