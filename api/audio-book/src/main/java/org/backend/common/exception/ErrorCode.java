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
    FILE_NOT_FOUND(2001, "File not found", HttpStatus.NOT_FOUND),
    FILE_NOT_IMAGE(2002, "File is not an image", HttpStatus.BAD_REQUEST),
    FILE_UPLOAD_FAILED(2003, "File upload failed", HttpStatus.INTERNAL_SERVER_ERROR),
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
