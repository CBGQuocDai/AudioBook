package org.backend.auth.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginRequest {
    @Email (message = "Email is not valid")
    private String email;
    @NotBlank(message = "Password is required")
    private String password;
}
