package org.backend.book.controller;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.response.BookResponse;
import org.backend.book.service.BookFavouriteService;
import org.backend.common.response.ApiResponse;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("books/favourite")
@RequiredArgsConstructor
public class BookFavouriteController {
    private final BookFavouriteService bookFavouriteService;
    @PostMapping("/{bookId}")
    public ApiResponse<Void> add(@PathVariable Long bookId) {
        bookFavouriteService.addFavourite(bookId);
        return ApiResponse.<Void>builder().build();
    }
    @DeleteMapping("/{bookId}")
    public ApiResponse<Void> remove(@PathVariable Long bookId) {
        bookFavouriteService.removeFavourite(bookId);
        return ApiResponse.<Void>builder().build();
    }
    @GetMapping
    public ApiResponse<List<BookResponse>> getMyFavourites() {
        return ApiResponse.<List<BookResponse>>builder()
                .data(bookFavouriteService.getMyFavourites())
                .build();
    }
}
