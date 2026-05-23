package org.backend.book.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateEbookChapterRequest {

    @NotBlank(message = "Ebook chapter title is required")
    private String title;

    @NotNull(message = "Ebook chapter number is required")
    @Positive(message = "Ebook chapter number must be greater than 0")
    private Integer chapterNumber;

    @NotNull(message = "Ebook chapter contentFileId is required")
    private Long contentFileId;

    @NotNull(message = "Ebook chapter audioFileId is required")
    private Long audioFileId;

    @NotNull(message = "Audio chapter duration is required")
    @Positive(message = "Audio chapter duration must be greater than 0")
    private Integer durationSeconds;
}
