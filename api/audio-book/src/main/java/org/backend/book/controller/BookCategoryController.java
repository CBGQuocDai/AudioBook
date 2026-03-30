package org.backend.book.controller;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.response.BookCategoryResponse;
import org.backend.book.service.BookCategoryService;
import org.backend.common.response.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("categories")
public class BookCategoryController {
    private final BookCategoryService bookCategoryService;

    @GetMapping
    public ApiResponse<List<BookCategoryResponse>> getAllCategories() {
        return ApiResponse.<List<BookCategoryResponse>>builder()
                .data(bookCategoryService.getAllCategories())
                .build();
    }
}
