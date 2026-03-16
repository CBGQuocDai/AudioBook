package org.backend.user.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.user.enums.RoleEnum;

@Getter
@Setter
@Builder
public class UserResponse {
    private long id;
    private String email;
    private String name;
    private String avatarUrl;
    private RoleEnum role;
}

