package org.backend.common.exception;


import lombok.Getter;

/**
 * Exception class representing logic and boundary failures in domain workflows.
 * Wraps predefined {@link ErrorCode} parameters to construct standardized HTTP error structures.
 */
@Getter
public class BusinessException extends RuntimeException {

    /**
     * Standard error code structure containing error details.
     */
    private final ErrorCode errorCode;

    /**
     * Constructs a BusinessException utilizing error code parameters.
     *
     * @param err target error code configuration
     */
    public BusinessException(ErrorCode err) {
        super(err.getMessage());
        this.errorCode = err;
    }

}

