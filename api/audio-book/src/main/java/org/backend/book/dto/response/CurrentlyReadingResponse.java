package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;

import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class CurrentlyReadingResponse {
    private Long id;
    private Long bookId;
    private String bookName;
    private String bookAuthor;
    private FileDto coverFile;
    private Long chapterId;
    private String chapterTitle;
    private Integer chapterNumber;
    private Integer pageNumber;
    private Float offsetInPage;
    private Float progressPercent;
    private LocalDateTime lastReadAt;
}
