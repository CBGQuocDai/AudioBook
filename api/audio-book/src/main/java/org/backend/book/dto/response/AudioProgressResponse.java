package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;

import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class AudioProgressResponse {
    // Thông tin tiến độ
    private Long id;
    private Integer currentTime;
    private Integer duration;
    private Float progressPercent;
    private Float playbackSpeed;
    private LocalDateTime lastPlayedAt;

    // Thông tin chương hiện tại
    private Long chapterId;
    private String chapterTitle;
    private Integer chapterNumber;
    private Integer chapterDurationSeconds;
    private FileDto chapterFile;

    // Thông tin sách (để hiển thị danh sách "Đang nghe dở")
    private Long bookId;
    private String bookName;
    private String bookAuthor;
    private FileDto bookCoverFile;
}
