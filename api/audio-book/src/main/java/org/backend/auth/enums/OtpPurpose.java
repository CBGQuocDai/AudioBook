package org.backend.auth.enums;



/**
 * Enum representing the purpose of an OTP (One-Time Password).
 */
public enum OtpPurpose {
    /**
     * OTP used for changing user email.
     */
    CHANGE_EMAIL,
    /**
     * OTP used for verifying user email during registration or activation.
     */
    VERIFY_EMAIL,
    /**
     * OTP used for resetting user password.
     */
    RESET_PASSWORD,
}
