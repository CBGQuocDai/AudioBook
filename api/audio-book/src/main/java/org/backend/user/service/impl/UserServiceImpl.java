package org.backend.user.service.impl;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.user.dto.request.AdminUserSearchRequest;
import org.backend.user.dto.request.CreateUserRequest;
import org.backend.user.dto.request.UpdateUserRequest;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.backend.user.enums.RoleEnum;
import org.backend.user.mapper.UserMapper;
import org.backend.user.repository.UserRepository;
import org.backend.user.service.UserService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByEmail(username);
    }

    @Override
    public UserResponse getMe(HttpServletRequest request) {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        String baseUrl = getBaseUrl(request);

        return userMapper.entityToResponse(user, baseUrl);
    }

    @Override
    public User getCurrentLoginUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new BusinessException(ErrorCode.UNAUTHORIZED);
        }

        Object principal = authentication.getPrincipal();
        if (principal == null || "anonymousUser".equals(principal)) {
            throw new BusinessException(ErrorCode.UNAUTHORIZED);
        }

        String email = authentication.getName();
        if (email == null || email.isBlank()) {
            throw new BusinessException(ErrorCode.UNAUTHORIZED);
        }

        User user = userRepository.findByEmail(email);
        if (user == null) {
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        return user;
    }

    @Override
    public List<UserResponse> getAllUsers(HttpServletRequest request) {
        String baseUrl = getBaseUrl(request);
        return userRepository.findAll().stream()
                .map(user -> userMapper.entityToResponse(user, baseUrl))
                .toList();
    }

    @Override
    public Page<UserResponse> searchUsers(AdminUserSearchRequest searchRequest, HttpServletRequest request) {
        Pageable pageable = searchRequest.toPageable();
        String keyword = searchRequest.getKeyword();

        Page<User> userPage = StringUtils.hasText(keyword)
                ? userRepository.searchByKeyword(keyword.trim(), pageable)
                : userRepository.findAll(pageable);

        String baseUrl = getBaseUrl(request);
        return userPage.map(user -> userMapper.entityToResponse(user, baseUrl));
    }

    @Override
    public UserResponse getUserById(Long id, HttpServletRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        return userMapper.entityToResponse(user, getBaseUrl(request));
    }

    @Override
    public UserResponse createUser(CreateUserRequest createUserRequest, HttpServletRequest request) {
        if (userRepository.existsByEmail(createUserRequest.getEmail())) {
            throw new BusinessException(ErrorCode.USER_EXIST);
        }

        RoleEnum role = createUserRequest.getRole() == null ? RoleEnum.USER : createUserRequest.getRole();
        User user = User.builder()
                .name(createUserRequest.getName())
                .email(createUserRequest.getEmail())
                .password(passwordEncoder.encode(createUserRequest.getPassword()))
                .role(role)
                .build();

        User savedUser = userRepository.save(user);
        return userMapper.entityToResponse(savedUser, getBaseUrl(request));
    }

    @Override
    public UserResponse updateUser(Long id, UpdateUserRequest updateUserRequest, HttpServletRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        String email = updateUserRequest.getEmail().trim();
        User existingUser = userRepository.findByEmail(email);
        if (existingUser != null && !existingUser.getId().equals(id)) {
            throw new BusinessException(ErrorCode.USER_EXIST);
        }

        user.setName(updateUserRequest.getName().trim());
        user.setEmail(email);
        user.setRole(updateUserRequest.getRole() == null ? user.getRole() : updateUserRequest.getRole());

        if (StringUtils.hasText(updateUserRequest.getPassword())) {
            user.setPassword(passwordEncoder.encode(updateUserRequest.getPassword()));
        }

        User savedUser = userRepository.save(user);
        return userMapper.entityToResponse(savedUser, getBaseUrl(request));
    }

    @Override
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        userRepository.delete(user);
    }

    private String getBaseUrl(HttpServletRequest request) {
        return request.getScheme() + "://" +
                request.getServerName() + ":" +
                request.getServerPort();
    }
}
