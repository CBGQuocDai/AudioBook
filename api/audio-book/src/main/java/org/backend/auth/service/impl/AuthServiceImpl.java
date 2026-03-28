package org.backend.auth.service.impl;


import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.auth.dto.request.*;
import org.backend.auth.dto.response.TokenResponse;
import org.backend.auth.service.AuthService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.common.util.JwtUtil;
import org.backend.common.util.OtpCodeUtil;
import org.backend.user.entity.User;
import org.backend.user.mapper.UserMapper;
import org.backend.user.repository.UserRepository;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;
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
    public TokenResponse verifyOtp(VerifyOtpRequest otp) {
        User user = userRepository.findByEmail(otp.getEmail());
        if(user == null) throw new BusinessException(ErrorCode.OTP_INVALID);
        String otpCode = cache.opsForValue().get(otp.getEmail()).toString();
        if(Objects.isNull(otpCode)||!otpCode.equals(otp.getOtp())) {
            throw new BusinessException(ErrorCode.OTP_INVALID);
        }
        user.setActive(true);
        return TokenResponse.builder()
                .token(jwtUtil.generateToken(user))
                .userInfo(userMapper.entityToResponse(user))
                .build();
    }


    @Override
    public void forgotPassword(ForgotPasswordRequest req) {
        if(userRepository.existsByEmailAndActive(req.getEmail(),true)) {
            String otp = OtpCodeUtil.generateOtpCode();
            cache.opsForValue().set(req.getEmail(), otp, 5, java.util.concurrent.TimeUnit.MINUTES);
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
    public void changePassword(ChangePasswordRequest req) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email);
        if(passwordEncoder.matches(req.getOldPassword(), user.getPassword())) {
            user.setPassword(passwordEncoder.encode(req.getNewPassword()));
        }
        else {
            throw new BusinessException(ErrorCode.PASSWORD_NOT_MATCH);
        }
    }

    @Override
    public void logout(String token) {
        Claims claims = jwtUtil.getClaims(token);
        cache.opsForValue().set(claims.getId(), token);
    }
}
