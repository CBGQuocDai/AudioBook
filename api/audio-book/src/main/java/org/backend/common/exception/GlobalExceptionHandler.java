package org.backend.common.exception;


import org.backend.common.response.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {


    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<?>> handleException(BusinessException e){
        ErrorCode errorCode = e.getErrorCode();
        ApiResponse resp = ApiResponse.builder().code(errorCode.getCode())
                .message(errorCode.getMessage()).build();
        return ResponseEntity.status(errorCode.getStatus()).body(resp);
    }
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<?>> handleException(Exception e){
        ApiResponse resp = ApiResponse.builder().code(500).message(e.getMessage()).build();
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(resp);
    }
}

