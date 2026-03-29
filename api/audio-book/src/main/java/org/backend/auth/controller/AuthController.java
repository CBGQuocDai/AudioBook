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

@RestController
@RequiredArgsConstructor
@RequestMapping("/auth")
@Validated
public class AuthController {
    private final AuthService authService;
    @PostMapping("/login")
    public ApiResponse<TokenResponse> login(@RequestBody LoginRequest loginRequest){
        return ApiResponse.<TokenResponse>builder()
                .data(authService.login(loginRequest))
                .build();
    }
    @DeleteMapping("/logout")
    public ApiResponse<Void> logout(@RequestHeader("Authorization") String token){
        authService.logout(token.substring(7));
        return ApiResponse.<Void>builder()
                .build();
    }
    @PostMapping("/otp/verify")
    public ApiResponse<TokenResponse> verifyOtp(@RequestBody VerifyOtpRequest req){
        return ApiResponse.<TokenResponse>builder()
                .data(authService.verifyOtp(req))
                .build();
    }
    @PreAuthorize("hasAuthority('VERIFY_EMAIL')")
    @PostMapping("active")
    public ApiResponse<TokenResponse> activeAccount(@RequestHeader("Authorization") String token){
        return ApiResponse.<TokenResponse>builder()
                .data(authService.activeAccount(token.substring(7)))
                .build();
    }
    @PostMapping("/otp/request")
    public ApiResponse<Void> requestOtp(@RequestBody OtpRequest req) {
        authService.requestOtp(req);
        return ApiResponse.<Void>builder().build();
    }
    @PostMapping("/forgot-password")
    public ApiResponse<Void> forgotPassword(@RequestBody OtpRequest req) {
        authService.forgotPassword(req);
        return ApiResponse.<Void>builder().build();
    }
    @PreAuthorize("hasAuthority('RESET_PASSWORD')")
    @PostMapping("/reset-password")
    public ApiResponse<Void> resetPassword(
            @RequestHeader("Authorization") String token,
            @RequestBody ResetPasswordRequest req) {
        authService.resetPassword(req, token.substring(7));
        return ApiResponse.<Void>builder().build();
    }
}

