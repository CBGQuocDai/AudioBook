package org.backend.payment.config;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Configuration properties for Stripe integration.
 * Binds properties prefixed with 'payment.stripe' from application configuration.
 */
@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "payment.stripe")
public class StripeProperties {

    /**
     * Secret API key for Stripe authentication.
     */
    @NotBlank
    private String secretKey;

    /**
     * Publishable API key for Stripe UI components.
     */
    @NotBlank
    private String publishableKey;

    /**
     * Webhook secret used to verify webhook signatures from Stripe.
     */
    private String webhookSecret;

    /**
     * Redirection URL after a successful Stripe payment.
     */
    private String successUrl;

    /**
     * Redirection URL after a canceled Stripe payment.
     */
    private String cancelUrl;
}

