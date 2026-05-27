package org.backend.common.response;


import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

/**
 * Standard generic structure for all HTTP responses in the application.
 *
 * @param <T> the data payload type
 */
@Builder
@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    /**
     * Application internal status or HTTP response code.
     */
    @Builder.Default
    private int code=1000;

    /**
     * Human-readable explanation of response status.
     */
    @Builder.Default
    private String message= "success";

    /**
     * Optional body/payload containing result data.
     */
    private T data;
}

