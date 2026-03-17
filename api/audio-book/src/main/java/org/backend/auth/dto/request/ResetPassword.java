package org.backend.auth.dto.request;

import jakarta.validation.constraints.NotBlank;

public class ResetPassword {
    @NotBlank(message = "password is required")
    private String password;
}
