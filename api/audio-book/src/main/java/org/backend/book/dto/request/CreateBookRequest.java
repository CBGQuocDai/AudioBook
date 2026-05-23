package org.backend.book.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CreateBookRequest {

    @NotBlank(message = "Book name is required")
    private String name;

    private String author;

    private String description;

    private Long coverFileId;

    @NotEmpty(message = "At least one category is required")
    private List<Long> categoryIds;

    @NotEmpty(message = "At least one ebook chapter is required")
    @Valid
    private List<CreateEbookChapterRequest> ebookChapters;

    private List<Long> descriptionImageFileIds;
}
