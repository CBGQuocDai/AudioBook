package org.backend.payment.exception;

/**
 * Exception thrown when an integration issue occurs with an external payment provider (e.g., Stripe).
 */
public class PaymentIntegrationException extends RuntimeException {

    /**
     * Constructs a new PaymentIntegrationException with the specified detail message and cause.
     *
     * @param message the detail message.
     * @param cause the cause of the exception.
     */
    public PaymentIntegrationException(String message, Throwable cause) {
        super(message, cause);
    }

    /**
     * Constructs a new PaymentIntegrationException with the specified detail message.
     *
     * @param message the detail message.
     */
    public PaymentIntegrationException(String message) {
        super(message);
    }
}

