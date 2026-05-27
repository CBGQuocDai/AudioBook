package org.backend.auth.controller;


import lombok.RequiredArgsConstructor;
import org.backend.auth.dto.request.*;
import org.backend.auth.dto.response.TokenResponse;
import org.backend.auth.service.AuthService;
import org.backend.auth.dto.request.OtpRequest;
import org.backend.auth.dto.request.ResetPasswordRequest;
import org.backend.auth.dto.request.VerifyOtpRequest;
import org.backend.common.response.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller providing authentication and authorization API endpoints.
 * Includes endpoints for credentials/Google login, OTP request/verification, account activation, logout, and password resets/changes.
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/auth")
@Validated
public class AuthController {
    /**
     * Service to process authentication and authorization logic.
     */
    private final AuthService authService;

    /**
     * Authenticates a user with email and password.
     *
     * @param loginRequest login credentials
     * @return API response containing the token and user details
     */
    @PostMapping("/login")
    public ApiResponse<TokenResponse> login(@RequestBody LoginRequest loginRequest){
        return ApiResponse.<TokenResponse>builder()
                .data(authService.login(loginRequest))
                .build();
    }

    /**
     * Authenticates a user via Google OAuth.
     *
     * @param request the payload containing Google ID Token
     * @return API response containing the token and user details
     */
    @PostMapping("/login/google")
    public ApiResponse<TokenResponse> loginWithGoogle(@RequestBody GoogleLoginRequest request){
        return ApiResponse.<TokenResponse>builder()
                .data(authService.loginWithGoogle(request))
                .build();
    }

    /**
     * Performs user logout by invalidating the current JWT token.
     *
     * @param token Authorization header containing JWT token prefixed with "Bearer "
     * @return empty API response
     */
    @DeleteMapping("/logout")
    public ApiResponse<Void> logout(@RequestHeader("Authorization") String token){
        authService.logout(token.substring(7));
        return ApiResponse.<Void>builder()
                .build();
    }

    /**
     * Verifies the submitted OTP code.
     *
     * @param req verification payload containing email, otp, and purpose
     * @return API response containing the verification token and user details
     */
    @PostMapping("/otp/verify")
    public ApiResponse<TokenResponse> verifyOtp(@RequestBody VerifyOtpRequest req){
        return ApiResponse.<TokenResponse>builder()
                .data(authService.verifyOtp(req))
                .build();
    }

    /**
     * Activates the user account using the verification token.
     * Requires 'VERIFY_EMAIL' authority.
     *
     * @param token Authorization header containing verification JWT token prefixed with "Bearer "
     * @return API response containing the active account token and user details
     */
    @PreAuthorize("hasAuthority('VERIFY_EMAIL')")
    @PostMapping("active")
    public ApiResponse<TokenResponse> activeAccount(@RequestHeader("Authorization") String token){
        return ApiResponse.<TokenResponse>builder()
                .data(authService.activeAccount(token.substring(7)))
                .build();
    }

    /**
     * Requests a new OTP for account verification.
     *
     * @param req request details containing user email
     * @return empty API response
     */
    @PostMapping("/otp/request")
    public ApiResponse<Void> requestOtp(@RequestBody OtpRequest req) {
        authService.requestOtp(req);
        return ApiResponse.<Void>builder().build();
    }

    /**
     * Initiates the forgot-password flow by sending an OTP to the user's email.
     *
     * @param req request details containing user email
     * @return empty API response
     */
    @PostMapping("/forgot-password")
    public ApiResponse<Void> forgotPassword(@RequestBody OtpRequest req) {
        authService.forgotPassword(req);
        return ApiResponse.<Void>builder().build();
    }

    /**
     * Resets the user password.
     * Requires 'RESET_PASSWORD' authority.
     *
     * @param token Authorization header containing reset JWT token prefixed with "Bearer "
     * @param req request details containing new password
     * @return empty API response
     */
    @PreAuthorize("hasAuthority('RESET_PASSWORD')")
    @PostMapping("/reset-password")
    public ApiResponse<Void> resetPassword(
            @RequestHeader("Authorization") String token,
            @RequestBody ResetPasswordRequest req) {
        authService.resetPassword(req, token.substring(7));
        return ApiResponse.<Void>builder().build();
    }

    /**
     * Changes password for the currently authenticated user.
     *
     * @param req request details containing old and new passwords
     * @return empty API response
     */
    @PostMapping("/change-password")
    public ApiResponse<Void> changePassword(
            @RequestBody ChangePasswordRequest req) {
        authService.changePassword(req);
        return ApiResponse.<Void>builder().build();
    }
}

