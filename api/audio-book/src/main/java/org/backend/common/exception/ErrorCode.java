package org.backend.common.exception;


import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum ErrorCode {
    USER_NOT_FOUND(1001, "user not exist", HttpStatus.BAD_REQUEST),
    LOGIN_FAIL(1001, "email or password is incorrect", HttpStatus.BAD_REQUEST),
    ;
    private int code;
    private String message;
    private HttpStatus status;

    ErrorCode(int i, String s, HttpStatus httpStatus) {
        this.code = i;
        this.message = s;
        this.status = httpStatus;
    }
}
