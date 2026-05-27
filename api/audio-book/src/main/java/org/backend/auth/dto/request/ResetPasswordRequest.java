package org.backend.auth.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

/**
 * Request payload for resetting password.
 */
@Getter
@Setter
public class ResetPasswordRequest {
    /**
     * The new password to be set. Cannot be blank.
     */
    @NotBlank(message = "password is required")
    private String password;
}
