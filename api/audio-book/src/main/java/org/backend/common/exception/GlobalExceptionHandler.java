package org.backend.common.exception;


import org.backend.common.response.ApiResponse;
import org.backend.payment.exception.BadRequestException;
import org.backend.payment.exception.PaymentIntegrationException;
import org.backend.payment.exception.ResourceNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {


    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<?>> handleException(BusinessException e){
        ErrorCode errorCode = e.getErrorCode();
        ApiResponse<?> resp = ApiResponse.builder().code(errorCode.getCode())
                .message(errorCode.getMessage()).build();
        return ResponseEntity.status(errorCode.getStatus()).body(resp);
    }
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<?>> handleException(Exception e){
        ApiResponse<?> resp = ApiResponse.builder().code(500).message(e.getMessage()).build();
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(resp);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<?>> handleValidationException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(org.springframework.validation.FieldError::getDefaultMessage)
                .orElse("Invalid request");

        ApiResponse<?> resp = ApiResponse.builder()
                .code(HttpStatus.BAD_REQUEST.value())
                .message(message)
                .build();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(resp);
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<?>> handleNotFoundException(ResourceNotFoundException e) {
        ApiResponse<?> resp = ApiResponse.builder()
                .code(HttpStatus.NOT_FOUND.value())
                .message(e.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(resp);
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ApiResponse<?>> handleBadRequestException(BadRequestException e) {
        ApiResponse<?> resp = ApiResponse.builder()
                .code(HttpStatus.BAD_REQUEST.value())
                .message(e.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(resp);
    }

    @ExceptionHandler(PaymentIntegrationException.class)
    public ResponseEntity<ApiResponse<?>> handlePaymentIntegrationException(PaymentIntegrationException e) {
        ApiResponse<?> resp = ApiResponse.builder()
                .code(HttpStatus.BAD_GATEWAY.value())
                .message(e.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(resp);
    }
}

