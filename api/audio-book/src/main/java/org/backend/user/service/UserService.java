package org.backend.user.service;

import jakarta.servlet.http.HttpServletRequest;
import org.backend.user.dto.request.AdminUserSearchRequest;
import org.backend.user.dto.request.CreateUserRequest;
import org.backend.user.dto.request.UpdateUserRequest;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface UserService extends UserDetailsService {
    UserResponse getMe(HttpServletRequest request);

    User getCurrentLoginUser();

    List<UserResponse> getAllUsers(HttpServletRequest request);

    Page<UserResponse> searchUsers(AdminUserSearchRequest searchRequest, HttpServletRequest request);

    UserResponse getUserById(Long id, HttpServletRequest request);

    UserResponse createUser(CreateUserRequest createUserRequest, HttpServletRequest request);

    UserResponse updateUser(Long id, UpdateUserRequest updateUserRequest, HttpServletRequest request);

    void deleteUser(Long id);
}
