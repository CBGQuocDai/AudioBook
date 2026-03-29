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

@Component
@Slf4j
public class JwtUtil {

    @Value("${app.jwt.expiration}")
    private long expiration;
    @Value("${app.jwt.issuer}")
    private String issuer;
    private final SecretKey key;
    public JwtUtil(@Value("${app.jwt.secret}") String secretKey) {
        this.key = Keys.hmacShaKeyFor(secretKey.getBytes());
    }
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
    public Claims getClaims(String token) {
        return Jwts.parser().verifyWith(this.key).build().parseClaimsJws(token).getBody();
    }
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

