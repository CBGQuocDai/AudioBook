package org.backend.auth.dto.request;

import jakarta.validation.constraints.Email;
import lombok.Getter;
import lombok.Setter;

/**
 * Request payload for generating or requesting an OTP.
 */
@Getter
@Setter
public class OtpRequest {
    /**
     * The email address to which the OTP should be sent. Must be a valid email format.
     */
    @Email(message = "email is invalid")
    private String email;
}
