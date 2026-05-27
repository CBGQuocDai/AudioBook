package org.backend.payment.enums;

/**
 * Represents the execution state of a payment transaction.
 */
public enum PaymentStatus {
    /**
     * Payment has been initiated but not yet completed.
     */
    PENDING,

    /**
     * Additional user action (e.g., 3D Secure authentication) is required.
     */
    REQUIRES_ACTION,

    /**
     * Payment successfully settled.
     */
    SUCCESS,

    /**
     * Payment attempt failed.
     */
    FAILED,

    /**
     * Payment was explicitly canceled.
     */
    CANCELED
}

