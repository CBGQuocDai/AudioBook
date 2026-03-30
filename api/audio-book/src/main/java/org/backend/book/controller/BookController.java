package org.backend.book.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.book.dto.request.AdminBookSearchRequest;
import org.backend.book.dto.response.BookResponse;
import org.backend.book.service.BookService;
import org.backend.common.response.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("books")
public class BookController {
    private final BookService bookService;

    @GetMapping("/search")
    public ApiResponse<Page<BookResponse>> searchBooks(@Valid @ModelAttribute AdminBookSearchRequest request) {
        return ApiResponse.<Page<BookResponse>>builder()
                .data(bookService.searchBooks(request))
                .build();
    }

    @GetMapping("/trending")
    public ApiResponse<Page<BookResponse>> getTrendingBooks(Pageable pageable) {
        return ApiResponse.<Page<BookResponse>>builder()
                .data(bookService.getTrendingBooks(pageable))
                .build();
    }

    @GetMapping("/new")
    public ApiResponse<Page<BookResponse>> getNewArrivals(Pageable pageable) {
        return ApiResponse.<Page<BookResponse>>builder()
                .data(bookService.getNewArrivals(pageable))
                .build();
    }

    @GetMapping("/{id}")
    public ApiResponse<BookResponse> getBookById(@PathVariable Long id) {
        return ApiResponse.<BookResponse>builder()
                .data(bookService.getBookById(id))
                .build();
    }
}
