package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;

@Getter
@Setter
@Builder
public class AudioBookChapterResponse {
    private Long id;
    private String title;
    private Integer chapterNumber;
    private Integer durationSeconds;
    private FileDto file;
}

