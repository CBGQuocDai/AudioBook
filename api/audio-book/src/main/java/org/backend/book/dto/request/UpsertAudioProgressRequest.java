package org.backend.book.dto.request;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpsertAudioProgressRequest {

    @NotNull(message = "bookId is required")
    private Long bookId;

    @NotNull(message = "chapterId is required")
    private Long chapterId;

    @NotNull(message = "currentTime is required")
    @Min(value = 0, message = "currentTime must be >= 0")
    private Integer currentTime;

    @NotNull(message = "duration is required")
    @Min(value = 1, message = "duration must be >= 1")
    private Integer duration;

    @NotNull(message = "progressPercent is required")
    @DecimalMin(value = "0.0", message = "progressPercent must be >= 0.0")
    @DecimalMax(value = "100.0", message = "progressPercent must be <= 100.0")
    private Float progressPercent;

    private Float playbackSpeed;
}
