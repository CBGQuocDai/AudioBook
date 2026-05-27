package org.backend.config.security;


import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.common.util.JwtUtil;
import org.backend.user.entity.User;
import org.backend.user.service.UserService;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * Filter that runs once per incoming request to intercept, parse, and validate JWT authorization headers.
 * Populates Spring Security's SecurityContext if a valid, non-blacklisted token is provided.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class JwtFilter extends OncePerRequestFilter {
    /**
     * Utility tool for verifying, parsing, and decomposing token signatures and claims.
     */
    private final JwtUtil jwtUtil;

    /**
     * User data provider service loaded by security authentication.
     */
    private final UserService userService;

    /**
     * Redis cache used for token blacklist checking.
     */
    private final RedisTemplate<String, Object> cache;

    /**
     * Inspects the Authorization header, validates the signature, asserts blacklist status,
     * resolves authorities including any additional token purpose claims, and injects authentication.
     *
     * @param request current HTTP request instance
     * @param response current HTTP response instance
     * @param filterChain subsequent filters in the servlet pipeline
     * @throws ServletException in case of filter execution errors
     * @throws IOException in case of underlying stream network failures
     */
    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,@NonNull FilterChain filterChain) throws ServletException, IOException {
        try {
            if(request.getHeader("Authorization")!= null) {
                String token = request.getHeader("Authorization").substring(7);
                log.info("Token in filter: {}", token);
                if(jwtUtil.validateToken(token)) {
                    Claims claims = jwtUtil.getClaims(token);
                    log.info("Claims: {}", claims);
                    if(!cache.hasKey(claims.getId())) {
                        User user = (User) userService.loadUserByUsername(claims.getSubject());
                        List<GrantedAuthority> authorities = new ArrayList<>();
                        authorities.addAll(user.getAuthorities());
                        String purpose = claims.get("purpose", String.class);
                        if(purpose != null) {
                            authorities.add(new SimpleGrantedAuthority(purpose));
                        }
                        UsernamePasswordAuthenticationToken authenticationToken =
                                new UsernamePasswordAuthenticationToken(user, null, authorities );
                        SecurityContextHolder.getContext().setAuthentication(authenticationToken);
                        log.info("User authenticated: {}", user.getEmail());
                    }
                }
            }
        } catch (Exception e) {
            log.error("Error: {}", e.getMessage());
        } finally {
            filterChain.doFilter(request, response);
        }
    }
}
