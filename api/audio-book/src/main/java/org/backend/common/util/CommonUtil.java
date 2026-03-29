package org.backend.common.util;

import java.util.Random;

public final class CommonUtil {

    private static final Random RANDOM = new Random();
    private static final String ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    private CommonUtil() {
    }

    public static String generateRandomAlphanumericString(int length) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append(ALPHANUMERIC.charAt(RANDOM.nextInt(ALPHANUMERIC.length())));
        }
        return sb.toString();
    }

    public static String generateRandomAlphanumericString() {
        return generateRandomAlphanumericString(16);
    }

    public static long getCurrentTimeStamp() {
        return System.currentTimeMillis();
    }
}

