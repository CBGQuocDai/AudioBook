package org.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

/**
 * Configuration class to enable JPA auditing.
 * Automatically injects the current authenticated user's name as the auditor for entities.
 */
@Configuration
@EnableJpaAuditing(auditorAwareRef = "auditorProvider")
public class EntityAuditingConfig {

    /**
     * Default name used for automated or unauthenticated auditing updates.
     */
    private static final String SYSTEM = "System";

    /**
     * Resolves the current auditor based on Spring Security Authentication context.
     * Returns "System" if the authentication context is empty, unauthenticated, or anonymous.
     *
     * @return an {@link AuditorAware} instance containing the auditor's name
     */
    @Bean
    public AuditorAware<String> auditorProvider() {
        return () -> {
            try {
                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

                if (authentication == null || !authentication.isAuthenticated()) {
                    return Optional.of(SYSTEM);
                }

                Object principal = authentication.getPrincipal();

                if (principal == null || "anonymousUser".equals(principal)) {
                    return Optional.of(SYSTEM);
                }

                String auditor = authentication.getName();
                if (auditor == null || auditor.isBlank()) {
                    return Optional.of(SYSTEM);
                }

                return Optional.of(auditor);
            } catch (Exception e) {
                return Optional.of(SYSTEM);
            }
        };
    }
}