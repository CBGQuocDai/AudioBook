package org.backend.auth.dto.response;


import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.user.dto.response.UserResponse;

/**
 * Response payload containing authentication token and user information.
 */
@Getter
@Setter
@Builder
public class TokenResponse {
    /**
     * The JWT authentication token.
     */
    private String token;
    /**
     * The details of the authenticated user.
     */
    private UserResponse userInfo;
}
