package org.backend.auth.dto.request;


import lombok.Getter;
import lombok.Setter;
import org.backend.auth.enums.OtpPurpose;

@Getter
@Setter
public class VerifyOtpRequest {
    private String otp;
    private String email;
    private OtpPurpose otpPurpose;
}
