package org.backend.auth.dto.request;

import jakarta.validation.constraints.Email;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ForgotPassword {
    @Email(message = "password is required")
    private String email;
}
