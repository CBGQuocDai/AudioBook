package org.backend.config.security;


import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Spring Security configuration class.
 * Defines public/private endpoints, CORS policy, password encoder, and integrates the custom JWT filter.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    /**
     * Set of endpoints accessible to anyone without authentication.
     */
    private final String[] PUBLIC_ENDPOINT ={
            "/auth/login", "/auth/login/google", "/client/register", "/auth/otp/verify",
            "/auth/otp/request", "/auth/forgot-password",
            "/payments/**", "/actuator/**"
    };

    /**
     * Configures the main HTTP security pipeline.
     * Sets up CORS configurations, disables CSRF, specifies route permissions, registers the exception entrypoint,
     * and maps JWT verification before username-password authentication.
     *
     * @param http the {@link HttpSecurity} object to configure filters and authorizations
     * @param entrypoint the exception entry point for unauthenticated requests
     * @param jwtFilter the filter processing incoming JWT tokens
     * @return the fully configured {@link SecurityFilterChain}
     * @throws Exception if a configuration error occurs
     */
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, AuthEntryPoint entrypoint, JwtFilter jwtFilter) throws Exception {
        http
                .cors(cors ->
                        cors.configurationSource(corsConfigurationSource()))
                .exceptionHandling(ex -> ex.authenticationEntryPoint(entrypoint))
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(req ->
                        req.requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                                .requestMatchers(PUBLIC_ENDPOINT).permitAll()
                                .requestMatchers("/admin/**").permitAll()
                                .anyRequest().authenticated()
                )
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    /**
     * Sets up the standard password encryptor using BCrypt hashing.
     *
     * @return a {@link BCryptPasswordEncoder} with strength 12
     */
    @Bean
    public PasswordEncoder passwordEncoder(){
        return new BCryptPasswordEncoder(12);
    }

    /**
     * Configures Cross-Origin Resource Sharing (CORS) rules.
     * Sets up headers, allowed methods, patterns for origins, and credential support.
     *
     * @return a source mapping the CORS configurations
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource(){
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedHeaders(List.of("*"));
        config.setAllowedMethods(List.of("OPTIONS", "GET", "POST", "PUT", "DELETE"));
        config.setAllowedOriginPatterns(List.of("*"));  
        config.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
