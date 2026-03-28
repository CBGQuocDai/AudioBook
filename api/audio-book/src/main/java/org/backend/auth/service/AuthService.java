package org.backend.auth.service;

import org.backend.auth.dto.request.*;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.auth.dto.response.TokenResponse;
import org.springframework.stereotype.Service;

@Service
public interface AuthService {
    TokenResponse login(LoginRequest loginRequest);
    TokenResponse verifyOtp(VerifyOtpRequest otp);
    void forgotPassword(ForgotPasswordRequest req);
    void resetPassword(ResetPasswordRequest req, String token);
    void changePassword(ChangePasswordRequest req);
    void logout(String token);
}

