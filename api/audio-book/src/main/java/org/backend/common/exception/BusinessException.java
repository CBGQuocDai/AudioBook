package org.backend.common.exception;


import lombok.Getter;

@Getter
public class BusinessException extends RuntimeException {
    private final ErrorCode errorCode;
    public BusinessException(ErrorCode err) {
        super(err.getMessage());
        this.errorCode = err;
    }

}

