package org.backend.book.dto.request;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpsertEbookProgressRequest {

    @NotNull(message = "bookId is required")
    private Long bookId;

    @NotNull(message = "chapterId is required")
    private Long chapterId;

    @NotNull(message = "pageNumber is required")
    @Min(value = 0, message = "pageNumber must be >= 0")
    private Integer pageNumber;

    @DecimalMin(value = "0.0", message = "offsetInPage must be >= 0.0")
    @DecimalMax(value = "1.0", message = "offsetInPage must be <= 1.0")
    private Float offsetInPage;

    @NotNull(message = "progressPercent is required")
    @DecimalMin(value = "0.0", message = "progressPercent must be >= 0.0")
    @DecimalMax(value = "100.0", message = "progressPercent must be <= 100.0")
    private Float progressPercent;
}
