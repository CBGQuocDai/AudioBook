package org.backend.common.util;

import java.util.Random;

public class OtpCodeUtil {

    public static String generateOtpCode(){
        StringBuilder sb = new StringBuilder();
        Random random = new Random();
        for(int i=0; i<6; i++){
            sb.append(random.nextInt(10));
        }
        return sb.toString();

    }
}
