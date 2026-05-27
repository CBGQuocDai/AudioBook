package org.backend.payment.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration class for the payment module.
 * Enables Stripe properties configuration.
 */
@Configuration
@EnableConfigurationProperties(StripeProperties.class)
public class PaymentConfig {
}

