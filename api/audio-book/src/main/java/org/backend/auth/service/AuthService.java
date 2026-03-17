package org.backend.auth.service;

import org.backend.auth.dto.request.LoginRequest;
import org.backend.auth.dto.request.RegisterRequest;
import org.backend.auth.dto.response.TokenResponse;
import org.springframework.stereotype.Service;

@Service
public interface AuthService {
    TokenResponse login(LoginRequest loginRequest);
    TokenResponse verifyOtp(String otp);
    void register(RegisterRequest registerRequest);
    void forgotPassword(String email);
    void resetPassword(String password);
    void logout(String token);
}

