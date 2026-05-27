package org.backend.auth.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

/**
 * Request payload for traditional email and password login.
 */
@Getter
@Setter
public class LoginRequest {
    /**
     * The email address of the user. Must be a valid email format.
     */
    @Email (message = "Email is not valid")
    private String email;
    /**
     * The password of the user. Cannot be blank.
     */
    @NotBlank(message = "Password is required")
    private String password;
}
