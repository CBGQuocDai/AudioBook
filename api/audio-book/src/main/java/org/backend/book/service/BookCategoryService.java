package org.backend.book.service;

import org.backend.book.dto.request.AdminBookCategorySearchRequest;
import org.backend.book.dto.request.CreateBookCategoryRequest;
import org.backend.book.dto.request.UpdateBookCategoryRequest;
import org.backend.book.dto.response.BookCategoryResponse;
import org.springframework.data.domain.Page;

import java.util.List;

public interface BookCategoryService {

    List<BookCategoryResponse> getAllCategories();

    Page<BookCategoryResponse> searchCategories(AdminBookCategorySearchRequest request);

    BookCategoryResponse getCategoryById(Long id);

    BookCategoryResponse createCategory(CreateBookCategoryRequest request);

    BookCategoryResponse updateCategory(Long id, UpdateBookCategoryRequest request);

    void deleteCategory(Long id);
}

