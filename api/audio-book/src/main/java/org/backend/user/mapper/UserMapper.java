package org.backend.user.mapper;

import org.backend.file.dto.FileDto;
import lombok.RequiredArgsConstructor;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.springframework.stereotype.Component;

/**
 * Mapper helper mapping database user structures onto representation response payloads.
 */
@Component
@RequiredArgsConstructor
public class UserMapper {


    /**
     * Converts a database User entity model into a customized UserResponse data transfer representation.
     * Handles nested mapping of user avatars safely.
     *
     * @param entity source User entity model
     * @return matching formatted UserResponse payload
     */
    public UserResponse entityToResponse(User entity){
        return UserResponse.builder()
                .id(entity.getId())
                .email(entity.getEmail())
                .name(entity.getName())
                .avatarFile(entity.getAvatarFile() == null ? null : new FileDto(entity.getAvatarFile()))
                .role(entity.getRole())
                .active(entity.getActive())
                .build();
    }
}

