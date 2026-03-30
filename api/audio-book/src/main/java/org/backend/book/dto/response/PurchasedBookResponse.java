package org.backend.book.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;

import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class PurchasedBookResponse {
    private Long id;
    private Long bookId;
    private String bookName;
    private String bookAuthor;
    private FileDto coverFile;
    private LocalDateTime purchasedAt;
    private Boolean isActive;
    private Boolean expired;
}
