package org.backend.book.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.backend.file.dto.FileDto;
import org.backend.file.entity.File;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class BookTopPurchasedResponse {
    private Long bookId;
    private String name;
    private String author;
    private FileDto coverFile;
    private long purchasedCount;

    public BookTopPurchasedResponse(Long bookId, String name, String author, File coverFile, long purchasedCount) {
        this.bookId = bookId;
        this.name = name;
        this.author = author;
        this.coverFile = coverFile == null ? null : new FileDto(coverFile);
        this.purchasedCount = purchasedCount;
    }
}