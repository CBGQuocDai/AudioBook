package org.backend.client.dto.request;


import jakarta.validation.constraints.Email;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ChangeEmailRequest {
    private String otp;
    @Email(message = "Email is not valid")
    private String newEmail;
}
