package org.backend.user.service;

import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

@Service
public interface UserService extends UserDetailsService {
    UserResponse getMe();
    User getCurrentLoginUser();
}
