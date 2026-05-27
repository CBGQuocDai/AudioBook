package org.backend.auth.service;

import org.backend.auth.dto.request.*;
import org.backend.auth.dto.response.TokenResponse;
import org.springframework.stereotype.Service;

/**
 * Service interface for handling all authentication and authorization operations.
 */
@Service
public interface AuthService {
    /**
     * Authenticates a user using email and password.
     *
     * @param loginRequest the credentials for logging in
     * @return the token and authenticated user info
     * @throws org.backend.exception.BusinessException if email/password is incorrect or user is not found
     */
    TokenResponse login(LoginRequest loginRequest);

    /**
     * Authenticates a user via Google OAuth ID token.
     *
     * @param request the Google login request payload containing the ID token
     * @return the token and authenticated user info
     * @throws org.backend.exception.BusinessException if the Google ID token is invalid
     */
    TokenResponse loginWithGoogle(GoogleLoginRequest request);

    /**
     * Verifies the provided OTP code for a specific purpose.
     *
     * @param otp the OTP verification details
     * @return the token and user info if verification is successful
     * @throws org.backend.exception.BusinessException if OTP is incorrect, expired, or not found
     */
    TokenResponse verifyOtp(VerifyOtpRequest otp);

    /**
     * Activates a user account using an activation token.
     *
     * @param token the activation token
     * @return the token and user info upon successful activation
     * @throws org.backend.exception.BusinessException if the token is invalid or expired
     */
    TokenResponse activeAccount(String token);

    /**
     * Requests a new OTP to be generated and sent.
     *
     * @param req the request payload with the target email
     * @throws org.backend.exception.BusinessException if the email is invalid or user does not exist
     */
    void requestOtp(OtpRequest req);

    /**
     * Requests an OTP for resetting password (forgot password flow).
     *
     * @param req the request payload with the target email
     * @throws org.backend.exception.BusinessException if the user is not found or OTP cannot be sent
     */
    void forgotPassword(OtpRequest req);

    /**
     * Resets the user's password using a reset token.
     *
     * @param req the new password details
     * @param token the verification or reset token
     * @throws org.backend.exception.BusinessException if the token is invalid, expired, or password mismatch occurs
     */
    void resetPassword(ResetPasswordRequest req, String token);

    /**
     * Invalidates the provided authentication token (logout).
     *
     * @param token the JWT token to invalidate
     */
    void logout(String token);

    /**
     * Changes the authenticated user's password.
     *
     * @param req the request payload containing old and new passwords
     * @throws org.backend.exception.BusinessException if old password does not match or the new password is invalid
     */
    void changePassword(ChangePasswordRequest req);
}

