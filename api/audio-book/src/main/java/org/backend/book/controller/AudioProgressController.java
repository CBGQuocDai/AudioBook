package org.backend.book.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.book.dto.request.UpsertAudioProgressRequest;
import org.backend.book.dto.response.AudioProgressResponse;
import org.backend.book.service.AudioProgressService;
import org.backend.common.response.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("books/progress/audio")
@RequiredArgsConstructor
public class AudioProgressController {

    private final AudioProgressService audioProgressService;

    @PostMapping
    public ApiResponse<AudioProgressResponse> upsertProgress(
            @Valid @RequestBody UpsertAudioProgressRequest request) {
        return ApiResponse.<AudioProgressResponse>builder()
                .data(audioProgressService.upsertProgress(request))
                .build();
    }

    @GetMapping("/{bookId}")
    public ApiResponse<AudioProgressResponse> getProgressByBookId(@PathVariable Long bookId) {
        return ApiResponse.<AudioProgressResponse>builder()
                .data(audioProgressService.getProgressByBookId(bookId))
                .build();
    }

    @GetMapping("/recent")
    public ApiResponse<Page<AudioProgressResponse>> getMyRecentProgress(Pageable pageable) {
        return ApiResponse.<Page<AudioProgressResponse>>builder()
                .data(audioProgressService.getMyRecentProgress(pageable))
                .build();
    }
}
