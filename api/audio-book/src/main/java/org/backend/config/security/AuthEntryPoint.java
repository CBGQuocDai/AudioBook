package org.backend.config.security;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.common.response.ApiResponse;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Authentication entry point invoked when an unauthenticated request attempts to access secured endpoints.
 * Returns a standardized JSON error response.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class AuthEntryPoint implements AuthenticationEntryPoint {

    /**
     * Mapper used to serialize the standardized API response to a JSON string.
     */
    private final ObjectMapper objectMapper;

    /**
     * Intercepts unauthenticated accesses, generates a HTTP 401 response, and writes a serialized {@link ApiResponse} block to the client body.
     *
     * @param request current HTTP request
     * @param response target HTTP response writer
     * @param authException authentication failure trigger
     * @throws IOException when failing to write to the response body
     * @throws ServletException for servlet environment problems
     */
    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException authException) throws IOException, ServletException {
        log.error("token: {}", request.getHeader("Authorization"));
        log.error("Unauthorized request");
        ApiResponse error = ApiResponse.builder().code(401).message("Unauthorized").build();
        response.setContentType("application/json");
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.getWriter().write(objectMapper.writeValueAsString(error));
    }
}

