package org.backend.user.mapper;


import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {


    public UserResponse entityToResponse(User entity, String baseUrl){
        return UserResponse.builder()
                .email(entity.getEmail())
                .name(entity.getName())
                .avatarUrl(baseUrl+"/api/users/avatar/"+entity.getId())
                .build();
    }
}

