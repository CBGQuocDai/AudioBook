package org.backend.user.service.impl;


import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.backend.user.mapper.UserMapper;
import org.backend.user.repository.UserRepository;
import org.backend.user.service.UserService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
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
    private final UserMapper userMapper;

    @Value("${aws.bucket-name}")
    private String bucketName;
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByEmail(username);
    }

    @Override
    public UserResponse getMe(HttpServletRequest request) {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
//        String baseUrl = request.getScheme() + "://" +
//                request.getServerName() + ":" +
//                request.getServerPort();
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(user.getAvatarPath())
                .build();
        GetObjectPresignRequest req= GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))
                .getObjectRequest(getObjectRequest).build();

        String avatarUrl  =s3Presigner.presignGetObject(req).url().toString();
        user.setAvatarPath(avatarUrl);
        return userMapper.entityToResponse(user);
    }
}

