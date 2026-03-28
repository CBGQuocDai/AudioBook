package org.backend.common.exception;


import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum ErrorCode {
    USER_NOT_FOUND(1001, "user not exist", HttpStatus.BAD_REQUEST),
    LOGIN_FAIL(1001, "email or password is incorrect", HttpStatus.BAD_REQUEST),
    UNAUTHORIZED(1003, "Unauthorized", HttpStatus.UNAUTHORIZED),
    FORBIDDEN(1004, "Forbidden", HttpStatus.FORBIDDEN),
    USER_EXIST(1005, "user already exists", HttpStatus.BAD_REQUEST),
    EMAIL_EXIST(1006, "email already exists", HttpStatus.BAD_REQUEST),
    OTP_INVALID(1007, "otp is invalid", HttpStatus.BAD_REQUEST),
    PASSWORD_NOT_MATCH(1008, "password does not match", HttpStatus.BAD_REQUEST),
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
