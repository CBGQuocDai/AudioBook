package org.backend.user.service;

import jakarta.servlet.http.HttpServletRequest;
import org.backend.user.dto.response.UserResponse;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

@Service
public interface UserService extends UserDetailsService {
    UserResponse getMe(HttpServletRequest request);
}

