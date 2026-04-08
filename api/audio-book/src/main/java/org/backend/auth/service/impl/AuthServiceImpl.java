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

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AuthServiceImpl implements AuthService {
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;
    private final RedisTemplate <String, Object> cache;
    private final EmailUtil emailUtil;
    private final ClientRepository clientRepository;

    @Value("${google.oauth.client-id:}")
    private String googleOauthClientId;

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

    @Override
    public void logout(String token) {
        Claims claims = jwtUtil.getClaims(token);
        if(claims.getExpiration().getTime() > System.currentTimeMillis()) {
            cache.opsForValue().set(claims.getId(), token,
                    claims.getExpiration().getTime()-System.currentTimeMillis(), TimeUnit.MILLISECONDS);
        }
    }

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
