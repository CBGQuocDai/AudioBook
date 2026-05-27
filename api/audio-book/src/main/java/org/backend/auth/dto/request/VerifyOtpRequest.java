package org.backend.auth.dto.request;


import lombok.Getter;
import lombok.Setter;
import org.backend.auth.enums.OtpPurpose;

/**
 * Request payload for verifying a One-Time Password (OTP).
 */
@Getter
@Setter
public class VerifyOtpRequest {
    /**
     * The OTP code to verify.
     */
    private String otp;
    /**
     * The email address associated with the OTP.
     */
    private String email;
    /**
     * The intended purpose of this OTP.
     */
    private OtpPurpose otpPurpose;
}
