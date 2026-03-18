package org.backend.auth.controller;


import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import org.backend.auth.dto.request.LoginRequest;
import org.backend.auth.dto.response.TokenResponse;
import org.backend.auth.service.AuthService;
import org.backend.common.response.ApiResponse;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ApiResponse<TokenResponse> login(@Validated @RequestBody LoginRequest loginRequest){
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


}

