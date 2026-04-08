package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;

import java.util.List;

@Getter
@Setter
@Builder
public class BookResponse {
    private Long id;
    private String name;
    private String author;
    private String description;
    private FileDto coverFile;
    private List<BookCategoryItemResponse> categories;
    private List<EbookChapterResponse> ebookChapters;
    private List<AudioBookChapterResponse> audioChapters;
    private List<FileDto> descriptionImages;
    private Integer isRead;
}

