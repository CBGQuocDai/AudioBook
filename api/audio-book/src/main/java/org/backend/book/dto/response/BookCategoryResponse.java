package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class BookCategoryResponse {
    private Long id;
    private String name;
    private String description;
}

