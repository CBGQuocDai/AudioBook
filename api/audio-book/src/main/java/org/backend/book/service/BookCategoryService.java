package org.backend.book.service;

import org.backend.book.dto.request.AdminBookCategorySearchRequest;
import org.backend.book.dto.request.CreateBookCategoryRequest;
import org.backend.book.dto.request.UpdateBookCategoryRequest;
import org.backend.book.dto.response.BookCategoryResponse;
import org.springframework.data.domain.Page;

public interface BookCategoryService {

    Page<BookCategoryResponse> searchCategories(AdminBookCategorySearchRequest request);

    BookCategoryResponse getCategoryById(Long id);

    BookCategoryResponse createCategory(CreateBookCategoryRequest request);

    BookCategoryResponse updateCategory(Long id, UpdateBookCategoryRequest request);

    void deleteCategory(Long id);
}

