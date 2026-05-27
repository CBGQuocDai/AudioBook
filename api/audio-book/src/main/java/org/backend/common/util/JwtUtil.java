package org.backend.common.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.backend.auth.enums.OtpPurpose;
import org.backend.user.entity.User;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.UUID;

/**
 * Utility helper component handling cryptographic sign operations, verification,
 * claims extraction, and creation of JWT authentication tokens.
 */
@Component
@Slf4j
public class JwtUtil {

    /**
     * Expiration interval configuration in milliseconds.
     */
    @Value("${app.jwt.expiration}")
    private long expiration;

    /**
     * Configured application identity string acting as the JWT issuer.
     */
    @Value("${app.jwt.issuer}")
    private String issuer;

    /**
     * Cryptographic signing key generated from configuration secrets.
     */
    private final SecretKey key;

    /**
     * Initializes the signing key based on the provided raw secret.
     *
     * @param secretKey secret string configuration
     */
    public JwtUtil(@Value("${app.jwt.secret}") String secretKey) {
        this.key = Keys.hmacShaKeyFor(secretKey.getBytes());
    }

    /**
     * Generates a standard JWT token loaded with user credentials and role claims.
     *
     * @param u the target user entity
     * @return the serialized JWT string token
     */
    public String generateToken(User u) {
        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .issuer(issuer)
                .setSubject(u.getEmail())
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + expiration))
                .claim("role", u.getRole())
                .signWith(key).compact();
    }

    /**
     * Generates a JWT token loaded with user credentials, role claims, and an OTP purpose restriction.
     *
     * @param u the target user entity
     * @param purpose targeted OTP action purpose
     * @return the serialized restricted JWT string token
     */
    public String generateToken(User u, OtpPurpose purpose) {
        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .issuer(issuer)
                .setSubject(u.getEmail())
                .claim("purpose", purpose.name() )
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + expiration))
                .claim("role", u.getRole())
                .signWith(key).compact();
    }

    /**
     * Validates and parses the token parameters using the cryptographic key.
     *
     * @param token target JWT string
     * @return the claims set parsed from the token
     */
    public Claims getClaims(String token) {
        return Jwts.parser().verifyWith(this.key).build().parseClaimsJws(token).getBody();
    }

    /**
     * Checks token signature validity, format sanity, and expiration status.
     *
     * @param token target JWT string to validate
     * @return true if token is mathematically valid and active, false otherwise
     */
    public boolean validateToken(String token) {
        try {
            getClaims(token);
            return true;
        } catch (Exception e) {
            log.warn("Invalid token: {} error: {}", token, e.getMessage());
            return false;
        }
    }
}

