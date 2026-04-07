package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;

import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class EbookProgressResponse {
    // Thông tin tiến độ
    private Long id;
    private Integer pageNumber;
    private Float offsetInPage;
    private Float progressPercent;
    private LocalDateTime lastReadAt;

    // Thông tin chương hiện tại
    private Long chapterId;
    private String chapterTitle;
    private Integer chapterNumber;
    private FileDto chapterFile;

    // Thông tin sách (để hiển thị danh sách "Đang đọc dở")
    private Long bookId;
    private String bookName;
    private String bookAuthor;
    private FileDto bookCoverFile;
}
