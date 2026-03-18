package org.backend.auth.dto.response;


import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.user.dto.response.UserResponse;

@Getter
@Setter
@Builder
public class TokenResponse {
    private String token;
    private UserResponse userInfo;
}
