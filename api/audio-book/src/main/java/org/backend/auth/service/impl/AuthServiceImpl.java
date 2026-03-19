package org.backend.auth.service.impl;


import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.auth.dto.request.LoginRequest;
import org.backend.auth.dto.request.RegisterRequest;
import org.backend.auth.dto.response.TokenResponse;
import org.backend.auth.service.AuthService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.common.util.JwtUtil;
import org.backend.user.entity.User;
import org.backend.user.mapper.UserMapper;
import org.backend.user.repository.UserRepository;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthServiceImpl implements AuthService {
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;
    private final RedisTemplate <String, Object> cache;

    @Override
    public TokenResponse login(LoginRequest loginRequest) {
        User u = userRepository.findByEmail(loginRequest.getEmail());

        if (u == null) {
            throw new BusinessException(ErrorCode.LOGIN_FAIL);
        }

        if (!passwordEncoder.matches(loginRequest.getPassword(), u.getPassword())) {
            throw new BusinessException(ErrorCode.LOGIN_FAIL);
        }

        return TokenResponse.builder()
                .token(jwtUtil.generateToken(u))
                .userInfo(userMapper.entityToResponse(u, ""))
                .build();
    }

    @Override
    public TokenResponse verifyOtp(String otp) {

        return null;
    }

    @Override
    public void register(RegisterRequest registerRequest) {

    }

    @Override
    public void forgotPassword(String email) {

    }

    @Override
    public void resetPassword(String password) {

    }
    @Override
    public void logout(String token) {
        Claims claims = jwtUtil.getClaims(token);
        cache.opsForValue().set(claims.getId(), token);
    }
}
