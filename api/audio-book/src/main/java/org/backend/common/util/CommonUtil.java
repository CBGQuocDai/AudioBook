package org.backend.common.util;

import java.util.Random;

/**
 * Helper utility class for common algorithms, timestamps, and alphanumeric generation tasks.
 */
public final class CommonUtil {

    /**
     * Internal secure random number generator.
     */
    private static final Random RANDOM = new Random();

    /**
     * Source characters for alphanumeric operations.
     */
    private static final String ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    /**
     * Private constructor to block instantiation.
     */
    private CommonUtil() {
    }

    /**
     * Generates a random alphanumeric token of a custom size.
     *
     * @param length length of output token
     * @return random alphanumeric sequence string
     */
    public static String generateRandomAlphanumericString(int length) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append(ALPHANUMERIC.charAt(RANDOM.nextInt(ALPHANUMERIC.length())));
        }
        return sb.toString();
    }

    /**
     * Generates a random alphanumeric token with default length of 16 characters.
     *
     * @return random alphanumeric sequence of 16 characters
     */
    public static String generateRandomAlphanumericString() {
        return generateRandomAlphanumericString(16);
    }

    /**
     * Resolves the current system epoch millisecond count.
     *
     * @return current epoch millisecond timestamp
     */
    public static long getCurrentTimeStamp() {
        return System.currentTimeMillis();
    }
}

