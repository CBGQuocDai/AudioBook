package org.backend.book.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class BookDashboardResponse {
    private long totalBooks;
    private List<BookTopFavoriteResponse> topFavoriteBooks;
    private List<BookTopPurchasedResponse> topPurchasedBooks;
}

