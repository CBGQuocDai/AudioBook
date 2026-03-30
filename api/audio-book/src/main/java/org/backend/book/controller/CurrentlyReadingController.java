package org.backend.book.controller;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.response.CurrentlyReadingResponse;
import org.backend.book.service.CurrentlyReadingService;
import org.backend.common.response.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("currently-reading")
public class CurrentlyReadingController {
    private final CurrentlyReadingService currentlyReadingService;

    @GetMapping
    public ApiResponse<Page<CurrentlyReadingResponse>> getCurrentlyReading(Pageable pageable) {
        return ApiResponse.<Page<CurrentlyReadingResponse>>builder()
                .data(currentlyReadingService.getCurrentlyReading(pageable))
                .build();
    }
}
