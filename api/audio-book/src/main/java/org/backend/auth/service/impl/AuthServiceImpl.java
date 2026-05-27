package org.backend.auth.service.impl;


import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.auth.dto.request.*;
import org.backend.auth.dto.response.TokenResponse;
import org.backend.auth.service.AuthService;
import org.backend.client.entity.Client;
import org.backend.client.repository.ClientRepository;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.common.util.EmailUtil;
import org.backend.common.util.JwtUtil;
import org.backend.common.util.OtpCodeUtil;
import org.backend.user.entity.User;
import org.backend.user.enums.RoleEnum;
import org.backend.user.mapper.UserMapper;
import org.backend.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import java.util.Objects;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Implementation of the {@link AuthService} interface.
 * Handles user login, Google OAuth login, OTP verification, account activation,
 * password resetting/changing, and logout functionality.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AuthServiceImpl implements AuthService {
    /**
     * Repository to manage User entities.
     */
    private final UserRepository userRepository;

    /**
     * Utility class for generating and parsing JWT tokens.
     */
    private final JwtUtil jwtUtil;

    /**
     * Password encoder to hash and verify user passwords.
     */
    private final PasswordEncoder passwordEncoder;

    /**
     * Mapper to convert between User entity and DTO.
     */
    private final UserMapper userMapper;

    /**
     * Redis template to cache OTP codes and blacklisted JWT tokens.
     */
    private final RedisTemplate <String, Object> cache;

    /**
     * Utility class to send OTP and transactional emails.
     */
    private final EmailUtil emailUtil;

    /**
     * Repository to manage Client entities.
     */
    private final ClientRepository clientRepository;

    /**
     * Client ID used to verify Google OAuth ID tokens.
     */
    @Value("${google.oauth.client-id:}")
    private String googleOauthClientId;

    /**
     * Authenticates a user using email and password.
     *
     * @param loginRequest the credentials for logging in
     * @return the token and authenticated user info
     * @throws BusinessException if user is not found, not active, or password is incorrect
     */
    @Override
    public TokenResponse login(LoginRequest loginRequest) {
        User u = userRepository.findByEmailAndActive(loginRequest.getEmail(),true);
        if (u == null) {
            throw new BusinessException(ErrorCode.LOGIN_FAIL);
        }
        if (!passwordEncoder.matches(loginRequest.getPassword(), u.getPassword())) {
            throw new BusinessException(ErrorCode.LOGIN_FAIL);
        }
        return TokenResponse.builder()
                .token(jwtUtil.generateToken(u))
                .userInfo(userMapper.entityToResponse(u))
                .build();
    }

    /**
     * Authenticates a user via Google OAuth ID token. Creates a new Client if not exists.
     *
     * @param request the Google login request payload containing the ID token
     * @return the token and authenticated user info
     * @throws BusinessException if token verification fails or email is not verified
     */
    @Override
    public TokenResponse loginWithGoogle(GoogleLoginRequest request) {
        log.info("=== Google Login Request Received ===");
        log.info("ID Token received, length: {}", request.getIdToken() != null ? request.getIdToken().length() : 0);

        GoogleIdToken.Payload payload = verifyGoogleIdToken(request.getIdToken());
        String email = payload.getEmail();
        log.info("Google token verified successfully. Email: {}, EmailVerified: {}", email, payload.getEmailVerified());

        if (email == null || email.isBlank()) {
            log.error("Email is null or blank from Google token");
            throw new BusinessException(ErrorCode.GOOGLE_TOKEN_INVALID);
        }

        if (Boolean.FALSE.equals(payload.getEmailVerified())) {
            log.error("Email not verified by Google");
            throw new BusinessException(ErrorCode.GOOGLE_TOKEN_INVALID);
        }

        String name = payload.get("name") != null
                ? payload.get("name").toString()
                : email.substring(0, email.indexOf("@"));

        Client client = clientRepository.findByEmail(email);
        if (client == null) {
            client = new Client();
            client.setEmail(email);
            client.setName(name);
            client.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
            client.setRole(RoleEnum.USER);
            client.setActive(true);
            client.setTotalCredit(0);
        } else {
            if (Boolean.FALSE.equals(client.getActive())) {
                client.setActive(true);
            }
            if (client.getName() == null || client.getName().isBlank()) {
                client.setName(name);
            }
        }

        Client savedClient = clientRepository.save(client);
        return TokenResponse.builder()
                .token(jwtUtil.generateToken(savedClient))
                .userInfo(userMapper.entityToResponse(savedClient))
                .build();
    }

    /**
     * Verifies the Google OAuth ID token against Google's servers.
     *
     * @param idToken the Google ID token
     * @return Google ID token payload
     * @throws BusinessException if Google client ID is not configured, or verification fails
     */
    private GoogleIdToken.Payload verifyGoogleIdToken(String idToken) {
        if (idToken == null || idToken.isBlank()) {
            log.error("ID Token is null or blank");
            throw new BusinessException(ErrorCode.GOOGLE_TOKEN_INVALID);
        }
        if (googleOauthClientId == null || googleOauthClientId.isBlank()) {
            log.error("Google OAuth Client ID not configured");
            throw new BusinessException(ErrorCode.GOOGLE_CLIENT_NOT_CONFIGURED);
        }

        log.info("Verifying Google token. Client ID: {}, Token length: {}", googleOauthClientId, idToken.length());

        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(),
                GsonFactory.getDefaultInstance()
        )
                .setAudience(Collections.singletonList(googleOauthClientId))
                .build();

        try {
            GoogleIdToken googleIdToken = verifier.verify(idToken);
            if (googleIdToken == null) {
                log.error("Google token verification failed - verifier returned null");
                throw new BusinessException(ErrorCode.GOOGLE_TOKEN_INVALID);
            }
            log.info("Google token verified successfully");
            return googleIdToken.getPayload();
        } catch (GeneralSecurityException ex) {
            log.error("Google token verification failed - GeneralSecurityException: {}", ex.getMessage());
            throw new BusinessException(ErrorCode.GOOGLE_TOKEN_INVALID);
        } catch (IOException ex) {
            log.error("Google token verification failed - IOException: {}", ex.getMessage());
            throw new BusinessException(ErrorCode.GOOGLE_TOKEN_INVALID);
        }
    }

    /**
     * Verifies the provided OTP code against the cached OTP code.
     *
     * @param otp the OTP verification details
     * @return token response with user details
     * @throws BusinessException if user is not found, cached OTP is not found, or OTP is incorrect
     */
    @Override
    public TokenResponse verifyOtp(VerifyOtpRequest otp) {
        User user = userRepository.findByEmail(otp.getEmail());
        if(user == null) throw new BusinessException(ErrorCode.OTP_INVALID);
        if(Objects.isNull(cache.opsForValue().get(otp.getEmail()))) throw new BusinessException(ErrorCode.OTP_INVALID);
        String otpCode = Objects.requireNonNull(cache.opsForValue()
                .get(otp.getEmail())
        ).toString();
        if(!otpCode.equals(otp.getOtp())) {
            throw new BusinessException(ErrorCode.OTP_INVALID);
        }
        cache.delete(otp.getEmail());
        return TokenResponse.builder()
                .token(jwtUtil.generateToken(user, otp.getOtpPurpose()))
                .userInfo(userMapper.entityToResponse(user))
                .build();
    }

    /**
     * Activates an inactive user account.
     *
     * @param token the activation token
     * @return the token response with user details
     */
    @Override
    public TokenResponse activeAccount(String token) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmailAndActive(email,false);
        user.setActive(true);
        Claims claims = jwtUtil.getClaims(token);
        if(claims.getExpiration().getTime() > System.currentTimeMillis()) {
            cache.opsForValue().set(claims.getId(), token,
                    claims.getExpiration().getTime()- System.currentTimeMillis(), TimeUnit.MINUTES);
        }
        return TokenResponse.builder()
                .token(jwtUtil.generateToken(user))
                .userInfo(userMapper.entityToResponse(user))
                .build();
    }

    /**
     * Generates and sends an OTP for account verification.
     *
     * @param req the OTP request containing target email
     * @throws BusinessException if user is not found
     */
    @Override
    public void requestOtp(OtpRequest req) {
        if(userRepository.existsByEmail(req.getEmail())) {
            String otp = OtpCodeUtil.generateOtpCode();
            cache.opsForValue().set(req.getEmail(), otp, 5, java.util.concurrent.TimeUnit.MINUTES);
            emailUtil.sendOtpEmail(
                    req.getEmail(),
                    otp,
                    "Mã OTP xác thực tài khoản",
                    "Bạn vừa yêu cầu xác thực tài khoản. Vui lòng nhập mã OTP bên dưới để tiếp tục.",
                    5
            );
        } else {
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
    }

    /**
     * Generates and sends an OTP for password resetting.
     *
     * @param req the OTP request containing target email
     * @throws BusinessException if active user with email is not found
     */
    @Override
    public void forgotPassword(OtpRequest req) {
        if(userRepository.existsByEmailAndActive(req.getEmail(),true)) {
            String otp = OtpCodeUtil.generateOtpCode();
            cache.opsForValue().set(req.getEmail(), otp, 5, java.util.concurrent.TimeUnit.MINUTES);
            emailUtil.sendOtpEmail(
                    req.getEmail(),
                    otp,
                    "Mã OTP đặt lại mật khẩu",
                    "Bạn vừa yêu cầu đặt lại mật khẩu. Vui lòng nhập mã OTP bên dưới để tiếp tục.",
                    5
            );
        } else {
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
    }

    /**
     * Resets user password and blacklists the reset token.
     *
     * @param req the password reset request
     * @param token the reset token
     * @throws BusinessException if active user is not found
     */
    @Override
    public void resetPassword(ResetPasswordRequest req, String token) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        log.info("email: {}", email);
        User user = userRepository.findByEmailAndActive(email,true);
        if(Objects.isNull(user)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        Claims claims = jwtUtil.getClaims(token);
        if(claims.getExpiration().getTime() > System.currentTimeMillis()) {
            cache.opsForValue().set(claims.getId(), token,
                   claims.getExpiration().getTime()-System.currentTimeMillis(), TimeUnit.MILLISECONDS);
        }
    }

    /**
     * Blacklists the JWT token to log the user out.
     *
     * @param token the JWT token to black list
     */
    @Override
    public void logout(String token) {
        Claims claims = jwtUtil.getClaims(token);
        if(claims.getExpiration().getTime() > System.currentTimeMillis()) {
            cache.opsForValue().set(claims.getId(), token,
                    claims.getExpiration().getTime()-System.currentTimeMillis(), TimeUnit.MILLISECONDS);
        }
    }

    /**
     * Changes the user's password.
     *
     * @param req the request payload with old and new passwords
     * @throws BusinessException if active user is not found or old password is correct
     */
    @Override
    public void changePassword(ChangePasswordRequest req) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmailAndActive(email,true);
        if(Objects.isNull(user)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        if(!passwordEncoder.matches(req.getOldPassword(), user.getPassword())) {
            throw new BusinessException(ErrorCode.OLD_PASSWORD_INCORRECT);
        }
        user.setPassword(passwordEncoder.encode(req.getNewPassword()));
    }
}
