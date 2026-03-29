package org.backend.user.service.impl;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.file.entity.File;
import org.backend.file.enums.FileType;
import org.backend.file.repository.FileRepository;
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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import java.util.List;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.time.Duration;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private final S3Client s3Client;
    private final S3Presigner  s3Presigner;
    private final UserRepository userRepository;
    private final FileRepository fileRepository;
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;


    @Value("${storage.aws.bucket-name}")
    private String bucketName;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByEmail(username);
    }

    @Override
    public UserResponse getMe() {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        UserResponse response = userMapper.entityToResponse(user);
        if (user.getAvatarFile() == null || !StringUtils.hasText(user.getAvatarFile().getFilePath())) {
            return response;
        }

        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(user.getAvatarFile().getFilePath())
                .build();
        GetObjectPresignRequest req = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))
                .getObjectRequest(getObjectRequest)
                .build();
        response.setAvatarUrl(s3Presigner.presignGetObject(req).url().toString());
        return response;
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
        return userRepository.findAll().stream()
                .map(user -> userMapper.entityToResponse(user))
                .toList();
    }

    @Override
    public Page<UserResponse> searchUsers(AdminUserSearchRequest searchRequest, HttpServletRequest request) {
        Pageable pageable = searchRequest.toPageable();
        String keyword = searchRequest.getKeyword();

        Page<User> userPage = StringUtils.hasText(keyword)
                ? userRepository.searchByKeyword(keyword.trim(), pageable)
                : userRepository.findAll(pageable);

        return userPage.map(user -> userMapper.entityToResponse(user));
    }

    @Override
    public UserResponse getUserById(Long id, HttpServletRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        return userMapper.entityToResponse(user);
    }

    @Override
    public UserResponse createUser(CreateUserRequest createUserRequest, HttpServletRequest request) {
        if (userRepository.existsByEmail(createUserRequest.getEmail())) {
            throw new BusinessException(ErrorCode.USER_EXIST);
        }

        File avatarFile = fileRepository.findById(createUserRequest.getAvatarFileId())
                .orElseThrow(() -> new BusinessException(ErrorCode.FILE_NOT_FOUND));
        if (!FileType.isImageFile(FileType.fromString(avatarFile.getType()))) {
            throw new BusinessException(ErrorCode.FILE_NOT_IMAGE);
        }

        RoleEnum role = createUserRequest.getRole() == null ? RoleEnum.USER : createUserRequest.getRole();
        User user = User.builder()
                .name(createUserRequest.getName())
                .email(createUserRequest.getEmail())
                .password(passwordEncoder.encode(createUserRequest.getPassword()))
                .avatarFile(avatarFile)
                .role(role)
                .build();

        User savedUser = userRepository.save(user);
        return userMapper.entityToResponse(savedUser);
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

        File avatarFile = fileRepository.findById(updateUserRequest.getAvatarFileId())
                .orElseThrow(() -> new BusinessException(ErrorCode.FILE_NOT_FOUND));
        if (!FileType.isImageFile(FileType.fromString(avatarFile.getType()))) {
            throw new BusinessException(ErrorCode.FILE_NOT_IMAGE);
        }

        user.setName(updateUserRequest.getName().trim());
        user.setEmail(email);
        user.setAvatarFile(avatarFile);
        user.setRole(updateUserRequest.getRole() == null ? user.getRole() : updateUserRequest.getRole());

        if (StringUtils.hasText(updateUserRequest.getPassword())) {
            user.setPassword(passwordEncoder.encode(updateUserRequest.getPassword()));
        }

        User savedUser = userRepository.save(user);
        return userMapper.entityToResponse(savedUser);
    }

    @Override
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        userRepository.delete(user);
    }
}
