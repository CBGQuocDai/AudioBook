package org.backend.common.util;

import java.util.Random;

/**
 * Utility helper class for generating One-Time Passwords (OTPs).
 */
public class OtpCodeUtil {

    /**
     * Generates a random 6-digit numeric OTP code.
     *
     * @return the generated 6-digit code string
     */
    public static String generateOtpCode(){
        StringBuilder sb = new StringBuilder();
        Random random = new Random();
        for(int i=0; i<6; i++){
            sb.append(random.nextInt(10));
        }
        return sb.toString();

    }
}
