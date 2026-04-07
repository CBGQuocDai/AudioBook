package org.backend.book.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.backend.book.dto.request.AdminBookCategorySearchRequest;
import org.backend.book.dto.request.AdminBookSearchRequest;
import org.backend.book.dto.request.CreateBookRequest;
import org.backend.book.dto.request.CreateBookCategoryRequest;
import org.backend.book.dto.request.UpdateBookRequest;
import org.backend.book.dto.request.UpdateBookCategoryRequest;
import org.backend.book.dto.response.BookDashboardResponse;
import org.backend.book.dto.response.BookResponse;
import org.backend.book.dto.response.BookCategoryResponse;
import org.backend.book.service.BookService;
import org.backend.book.service.BookCategoryService;
import org.backend.common.response.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/books")
@PreAuthorize("hasRole('ADMIN')")
public class AdminBookController {

    private final BookCategoryService bookCategoryService;
    private final BookService bookService;

    @GetMapping("/dashboard")
    public ApiResponse<BookDashboardResponse> getDashboard() {
        return ApiResponse.<BookDashboardResponse>builder()
                .data(bookService.getDashboard())
                .build();
    }

    @PostMapping
    public ApiResponse<BookResponse> createBook(@Valid @RequestBody CreateBookRequest request) {
        return ApiResponse.<BookResponse>builder()
                .data(bookService.createBook(request))
                .build();
    }

    @GetMapping("/search")
    public ApiResponse<Page<BookResponse>> searchBooks(@Valid @ModelAttribute AdminBookSearchRequest request) {
        return ApiResponse.<Page<BookResponse>>builder()
                .data(bookService.searchBooks(request))
                .build();
    }

    @GetMapping("/{id}")
    public ApiResponse<BookResponse> getBookById(@PathVariable Long id) {
        return ApiResponse.<BookResponse>builder()
                .data(bookService.getBookById(id))
                .build();
    }

    @PutMapping("/{id}")
    public ApiResponse<BookResponse> updateBook(@PathVariable Long id,
                                                @Valid @RequestBody UpdateBookRequest request) {
        return ApiResponse.<BookResponse>builder()
                .data(bookService.updateBook(id, request))
                .build();
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteBook(@PathVariable Long id) {
        bookService.deleteBook(id);
        return ApiResponse.<Void>builder().build();
    }

    @GetMapping("/categories/search")
    public ApiResponse<Page<BookCategoryResponse>> searchCategories(
            @Valid @ModelAttribute AdminBookCategorySearchRequest searchRequest) {
        return ApiResponse.<Page<BookCategoryResponse>>builder()
                .data(bookCategoryService.searchCategories(searchRequest))
                .build();
    }

    @GetMapping("/categories/{id}")
    public ApiResponse<BookCategoryResponse> getCategoryById(@PathVariable Long id) {
        return ApiResponse.<BookCategoryResponse>builder()
                .data(bookCategoryService.getCategoryById(id))
                .build();
    }

    @PostMapping("/categories")
    public ApiResponse<BookCategoryResponse> createCategory(
            @Valid @RequestBody CreateBookCategoryRequest request) {
        return ApiResponse.<BookCategoryResponse>builder()
                .data(bookCategoryService.createCategory(request))
                .build();
    }

    @PutMapping("/categories/{id}")
    public ApiResponse<BookCategoryResponse> updateCategory(
            @PathVariable Long id,
            @Valid @RequestBody UpdateBookCategoryRequest request) {
        return ApiResponse.<BookCategoryResponse>builder()
                .data(bookCategoryService.updateCategory(id, request))
                .build();
    }

    @DeleteMapping("/categories/{id}")
    public ApiResponse<Void> deleteCategory(@PathVariable Long id) {
        bookCategoryService.deleteCategory(id);
        return ApiResponse.<Void>builder().build();
    }
}
