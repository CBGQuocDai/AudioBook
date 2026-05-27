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

/**
 * Intercepts thrown exceptions application-wide and maps them into uniform JSON HTTP responses.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {


    /**
     * Catches and transforms custom {@link BusinessException} into standard {@link ApiResponse} blocks.
     * Uses status and codes specified by the BusinessException's internal {@link ErrorCode}.
     *
     * @param e the business exception thrown
     * @return a {@link ResponseEntity} holding details of the business logic error
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<?>> handleException(BusinessException e){
        ErrorCode errorCode = e.getErrorCode();
        ApiResponse<?> resp = ApiResponse.builder().code(errorCode.getCode())
                .message(errorCode.getMessage()).build();
        return ResponseEntity.status(errorCode.getStatus()).body(resp);
    }

    /**
     * Fallback processor matching unexpected server {@link RuntimeException} entities.
     * Returns a HTTP 500 error payload containing the message.
     *
     * @param e the unhandled runtime exception
     * @return a {@link ResponseEntity} representing an internal server error
     */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<?>> handleException(Exception e){
        ApiResponse<?> resp = ApiResponse.builder().code(500).message(e.getMessage()).build();
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(resp);
    }

    /**
     * Maps validation failures from Spring MVC payload bindings (e.g. invalid request structures).
     * Extracts and returns the first constraint violation message.
     *
     * @param e the payload validation exception
     * @return a {@link ResponseEntity} with status 400 Bad Request
     */
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

    /**
     * Maps resource-not-found scenario failures.
     *
     * @param e the exception detailing the missing resource
     * @return a {@link ResponseEntity} with status 404 Not Found
     */
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<?>> handleNotFoundException(ResourceNotFoundException e) {
        ApiResponse<?> resp = ApiResponse.builder()
                .code(HttpStatus.NOT_FOUND.value())
                .message(e.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(resp);
    }

    /**
     * Handles bad request scenarios specifically thrown in workflows.
     *
     * @param e the bad request exception
     * @return a {@link ResponseEntity} with status 400 Bad Request
     */
    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ApiResponse<?>> handleBadRequestException(BadRequestException e) {
        ApiResponse<?> resp = ApiResponse.builder()
                .code(HttpStatus.BAD_REQUEST.value())
                .message(e.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(resp);
    }

    /**
     * Processes failures occurring during third-party payment system operations (e.g. Stripe errors).
     *
     * @param e the payment integration exception
     * @return a {@link ResponseEntity} with status 502 Bad Gateway
     */
    @ExceptionHandler(PaymentIntegrationException.class)
    public ResponseEntity<ApiResponse<?>> handlePaymentIntegrationException(PaymentIntegrationException e) {
        ApiResponse<?> resp = ApiResponse.builder()
                .code(HttpStatus.BAD_GATEWAY.value())
                .message(e.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(resp);
    }
}

