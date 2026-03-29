package org.backend.user.controller;


import jakarta.servlet.http.HttpServletRequest;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.ChangeNameRequest;
import org.backend.client.dto.response.ClientResponse;
import org.backend.common.response.ApiResponse;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.service.UserService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/mobile/users")
public class UserController {

    private final UserService userService;
    @GetMapping("/me")
    public ApiResponse<UserResponse> getMe(){
        return ApiResponse.<UserResponse>builder()
                .data(userService.getMe())
                .build();
    }

}