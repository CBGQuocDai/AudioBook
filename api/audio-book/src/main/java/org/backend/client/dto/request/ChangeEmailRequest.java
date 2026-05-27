package org.backend.client.dto.request;


import jakarta.validation.constraints.Email;
import lombok.Getter;
import lombok.Setter;

/**
 * Request DTO to finalize changing the client's email with an OTP.
 */
@Getter
@Setter
public class ChangeEmailRequest {
    /**
     * The OTP verification code sent to the client's new email.
     */
    private String otp;

    /**
     * The new email address that was pre-registered for confirmation.
     */
    @Email(message = "Email is not valid")
    private String newEmail;
}
