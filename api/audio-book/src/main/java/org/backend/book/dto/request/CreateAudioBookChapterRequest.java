package org.backend.book.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateAudioBookChapterRequest {

    @NotBlank(message = "Audio chapter title is required")
    private String title;

    @NotNull(message = "Audio chapter number is required")
    @Positive(message = "Audio chapter number must be greater than 0")
    private Integer chapterNumber;

    @NotNull(message = "Audio chapter duration is required")
    @Positive(message = "Audio chapter duration must be greater than 0")
    private Integer durationSeconds;

    @NotNull(message = "Audio chapter fileId is required")
    private Long fileId;
}

