package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;

@Getter
@Setter
@Builder
public class EbookChapterResponse {
    private Long id;
    private String title;
    private Integer chapterNumber;
    private FileDto file;
}

