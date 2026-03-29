package org.backend.auth.dto.request;

import jakarta.validation.constraints.Email;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class OtpRequest {
    @Email(message = "email is invalid")
    private String email;
}
