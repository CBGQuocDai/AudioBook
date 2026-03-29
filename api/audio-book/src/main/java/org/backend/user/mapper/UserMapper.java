package org.backend.user.mapper;


import org.backend.file.dto.FileDto;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {


    public UserResponse entityToResponse(User entity){
        return UserResponse.builder()
                .id(entity.getId())
                .email(entity.getEmail())
                .name(entity.getName())
                .avatarFile(entity.getAvatarFile() == null ? null : new FileDto(entity.getAvatarFile()))
                .role(entity.getRole())
                .build();
    }
}

