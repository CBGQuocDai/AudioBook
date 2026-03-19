package org.backend.user.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.common.response.ApiResponse;
import org.backend.user.dto.request.AdminUserSearchRequest;
import org.backend.user.dto.request.CreateUserRequest;
import org.backend.user.dto.request.UpdateUserRequest;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.service.UserService;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/users")
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    private final UserService userService;

    @GetMapping("/search")
    public ApiResponse<Page<UserResponse>> searchUsers(
            @Valid @ModelAttribute AdminUserSearchRequest searchRequest,
            HttpServletRequest request) {
        return ApiResponse.<Page<UserResponse>>builder()
                .data(userService.searchUsers(searchRequest, request))
                .build();
    }

    @GetMapping("/{id}")
    public ApiResponse<UserResponse> getUserById(@PathVariable Long id,
            HttpServletRequest request) {
        return ApiResponse.<UserResponse>builder()
                .data(userService.getUserById(id, request))
                .build();
    }

    @PostMapping
    public ApiResponse<UserResponse> createUser(
            @Valid @RequestBody CreateUserRequest createUserRequest,
            HttpServletRequest request) {
        return ApiResponse.<UserResponse>builder()
                .data(userService.createUser(createUserRequest, request))
                .build();
    }

    @PutMapping("/{id}")
    public ApiResponse<UserResponse> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRequest updateUserRequest,
            HttpServletRequest request) {
        return ApiResponse.<UserResponse>builder()
                .data(userService.updateUser(id, updateUserRequest, request))
                .build();
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ApiResponse.<Void>builder().build();
    }
}
