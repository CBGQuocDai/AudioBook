package org.backend.payment.exception;

/**
 * Exception thrown when a payment request contains invalid or malformed arguments.
 */
public class BadRequestException extends RuntimeException {

    /**
     * Constructs a new BadRequestException with the specified detail message.
     *
     * @param message the detail message.
     */
    public BadRequestException(String message) {
        super(message);
    }
}

