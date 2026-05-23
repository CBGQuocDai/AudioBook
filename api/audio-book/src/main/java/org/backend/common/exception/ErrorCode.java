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
    BOOK_NOT_FOUND(3000, "book not found", HttpStatus.BAD_REQUEST),
    BOOK_CATEGORY_NOT_FOUND(3001, "book category not found", HttpStatus.BAD_REQUEST),
    BOOK_CATEGORY_EXIST(3002, "book category already exists", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_CATEGORY_IDS(3003, "book category ids are invalid", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_FILE_IDS(3004, "book file ids are invalid", HttpStatus.BAD_REQUEST),
    BOOK_EBOOK_CHAPTER_NUMBER_DUPLICATE(3005, "duplicate ebook chapter number", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_AUDIO_FILE_TYPE(3007, "audio chapter file must be audio type", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_EBOOK_FILE_TYPE(3015, "ebook chapter content file must be document type", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_CHAPTER_CONTENT_TYPE(3016, "chapter content type must be audio or ebook", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_DESCRIPTION_IMAGE_IDS(3008, "book description image file ids are invalid", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_DESCRIPTION_IMAGE_FILE_TYPE(3009, "description image file must be image type", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_COVER_FILE_TYPE(3010, "cover file must be image type", HttpStatus.BAD_REQUEST),
    FILE_NOT_FOUND(2001, "File not found", HttpStatus.NOT_FOUND),
    FILE_NOT_IMAGE(2002, "File is not an image", HttpStatus.BAD_REQUEST),
    FILE_UPLOAD_FAILED(2003, "File upload failed", HttpStatus.INTERNAL_SERVER_ERROR),

    NO_PERMISSION(1009, "no permission", HttpStatus.FORBIDDEN),
    OLD_PASSWORD_INCORRECT(1010, "old password does not match", HttpStatus.BAD_REQUEST),
    GOOGLE_TOKEN_INVALID(1011, "google token is invalid", HttpStatus.BAD_REQUEST),
    GOOGLE_CLIENT_NOT_CONFIGURED(1012, "google client id is not configured", HttpStatus.INTERNAL_SERVER_ERROR),

    EBOOK_CHAPTER_NOT_FOUND(3011, "ebook chapter not found", HttpStatus.BAD_REQUEST),
    AUDIO_CHAPTER_NOT_FOUND(3012, "audio chapter not found", HttpStatus.BAD_REQUEST),
    CHAPTER_NOT_BELONG_TO_BOOK(3013, "chapter does not belong to this book", HttpStatus.BAD_REQUEST),
    PROGRESS_NOT_FOUND(3014, "progress not found", HttpStatus.BAD_REQUEST),
    SUBSCRIPTION_NOT_FOUND(20000, "subscription not found", HttpStatus.NOT_FOUND),
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
