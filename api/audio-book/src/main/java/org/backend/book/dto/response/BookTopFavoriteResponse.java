package org.backend.book.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class BookTopFavoriteResponse {
    private Long bookId;
    private String name;
    private String author;
    private long favoriteCount;
}

