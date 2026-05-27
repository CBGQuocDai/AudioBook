package org.backend.client.enums;

/**
 * Represents the status of a subscription.
 */
public enum Status {

    /**
     * The subscription is pending payment or activation.
     */
    PENDING,

    /**
     * The subscription is active and valid.
     */
    ACTIVE,

    /**
     * The subscription has been canceled.
     */
    CANCELED
}
