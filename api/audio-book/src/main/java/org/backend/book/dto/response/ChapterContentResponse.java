package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class ChapterContentResponse {
    private String bookName;
    private String chapterTitle;
    private Integer chapterNumber;
    private String type;
    private String audioPath;
    private String content;
}
