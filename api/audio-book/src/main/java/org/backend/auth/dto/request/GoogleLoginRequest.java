package org.backend.auth.dto.request;

import lombok.Getter;
import lombok.Setter;

/**
 * Request payload for logging in via Google OAuth.
 */
@Getter
@Setter
public class GoogleLoginRequest {
    /**
     * The ID token provided by Google OAuth API.
     */
    private String idToken;
}
