package org.backend.book.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.book.dto.request.UpsertEbookProgressRequest;
import org.backend.book.dto.response.EbookProgressResponse;
import org.backend.book.service.EbookProgressService;
import org.backend.common.response.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("books/progress/ebook")
@RequiredArgsConstructor
public class EbookProgressController {

    private final EbookProgressService ebookProgressService;

    @PostMapping
    public ApiResponse<EbookProgressResponse> upsertProgress(
            @Valid @RequestBody UpsertEbookProgressRequest request) {
        return ApiResponse.<EbookProgressResponse>builder()
                .data(ebookProgressService.upsertProgress(request))
                .build();
    }

    @GetMapping("/{bookId}")
    public ApiResponse<EbookProgressResponse> getProgressByBookId(@PathVariable Long bookId) {
        return ApiResponse.<EbookProgressResponse>builder()
                .data(ebookProgressService.getProgressByBookId(bookId))
                .build();
    }

    @GetMapping("/recent")
    public ApiResponse<Page<EbookProgressResponse>> getMyRecentProgress(Pageable pageable) {
        return ApiResponse.<Page<EbookProgressResponse>>builder()
                .data(ebookProgressService.getMyRecentProgress(pageable))
                .build();
    }
}
