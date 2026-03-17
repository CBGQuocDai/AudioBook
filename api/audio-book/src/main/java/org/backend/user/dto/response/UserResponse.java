package org.backend.user.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class UserResponse {
    private long id;
    private String email;
    private String name;
    private String avatarUrl;
}

