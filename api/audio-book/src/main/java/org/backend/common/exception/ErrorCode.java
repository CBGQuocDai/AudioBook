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
    BOOK_NOT_FOUND(3000, "book not found", HttpStatus.BAD_REQUEST),
    BOOK_CATEGORY_NOT_FOUND(3001, "book category not found", HttpStatus.BAD_REQUEST),
    BOOK_CATEGORY_EXIST(3002, "book category already exists", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_CATEGORY_IDS(3003, "book category ids are invalid", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_FILE_IDS(3004, "book file ids are invalid", HttpStatus.BAD_REQUEST),
    BOOK_EBOOK_CHAPTER_NUMBER_DUPLICATE(3005, "duplicate ebook chapter number", HttpStatus.BAD_REQUEST),
    BOOK_AUDIO_CHAPTER_NUMBER_DUPLICATE(3006, "duplicate audio chapter number", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_AUDIO_FILE_TYPE(3007, "audio chapter file must be audio type", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_DESCRIPTION_IMAGE_IDS(3008, "book description image file ids are invalid", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_DESCRIPTION_IMAGE_FILE_TYPE(3009, "description image file must be image type", HttpStatus.BAD_REQUEST),
    BOOK_INVALID_COVER_FILE_TYPE(3010, "cover file must be image type", HttpStatus.BAD_REQUEST),
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
