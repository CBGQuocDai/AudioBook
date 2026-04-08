package org.backend.auth.service;

import org.backend.auth.dto.request.*;
import org.backend.auth.dto.response.TokenResponse;
import org.springframework.stereotype.Service;

@Service
public interface AuthService {
    TokenResponse login(LoginRequest loginRequest);
    TokenResponse loginWithGoogle(GoogleLoginRequest request);
    TokenResponse verifyOtp(VerifyOtpRequest otp);
    TokenResponse activeAccount(String token);
    void requestOtp(OtpRequest req);
    void forgotPassword( OtpRequest req);
    void resetPassword(ResetPasswordRequest req, String token);
    void logout(String token);
    void changePassword(ChangePasswordRequest req);
}

