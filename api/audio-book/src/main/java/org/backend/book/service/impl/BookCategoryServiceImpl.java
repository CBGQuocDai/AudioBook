package org.backend.book.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.request.AdminBookCategorySearchRequest;
import org.backend.book.dto.request.CreateBookCategoryRequest;
import org.backend.book.dto.request.UpdateBookCategoryRequest;
import org.backend.book.dto.response.BookCategoryResponse;
import org.backend.book.entity.BookCategory;
import org.backend.book.repository.BookCategoryRepository;
import org.backend.book.service.BookCategoryService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BookCategoryServiceImpl implements BookCategoryService {

    private final BookCategoryRepository bookCategoryRepository;

    @Override
    public List<BookCategoryResponse> getAllCategories() {
        return bookCategoryRepository.findAll().stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    public Page<BookCategoryResponse> searchCategories(AdminBookCategorySearchRequest request) {
        Pageable pageable = request.toPageable();
        String keyword = request.getKeyword();

        Page<BookCategory> categories = StringUtils.hasText(keyword)
                ? bookCategoryRepository.searchByKeyword(keyword.trim(), pageable)
                : bookCategoryRepository.findAll(pageable);

        return categories.map(this::toResponse);
    }

    @Override
    public BookCategoryResponse getCategoryById(Long id) {
        BookCategory category = bookCategoryRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.BOOK_CATEGORY_NOT_FOUND));
        return toResponse(category);
    }

    @Override
    @Transactional
    public BookCategoryResponse createCategory(CreateBookCategoryRequest request) {
        String categoryName = request.getName().trim();
        validateUniqueName(categoryName, null);

        BookCategory category = BookCategory.builder()
                .name(categoryName)
                .description(normalizeDescription(request.getDescription()))
                .build();

        return toResponse(bookCategoryRepository.save(category));
    }

    @Override
    @Transactional
    public BookCategoryResponse updateCategory(Long id, UpdateBookCategoryRequest request) {
        BookCategory category = bookCategoryRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.BOOK_CATEGORY_NOT_FOUND));

        String categoryName = request.getName().trim();
        validateUniqueName(categoryName, id);

        category.setName(categoryName);
        category.setDescription(normalizeDescription(request.getDescription()));

        return toResponse(bookCategoryRepository.save(category));
    }

    @Override
    @Transactional
    public void deleteCategory(Long id) {
        BookCategory category = bookCategoryRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.BOOK_CATEGORY_NOT_FOUND));
        bookCategoryRepository.delete(category);
    }

    private void validateUniqueName(String categoryName, Long id) {
        if (id == null) {
            if (bookCategoryRepository.existsByNameIgnoreCase(categoryName)) {
                throw new BusinessException(ErrorCode.BOOK_CATEGORY_EXIST);
            }
            return;
        }

        if (bookCategoryRepository.existsByNameIgnoreCaseAndIdNot(categoryName, id)) {
            throw new BusinessException(ErrorCode.BOOK_CATEGORY_EXIST);
        }
    }

    private String normalizeDescription(String description) {
        return StringUtils.hasText(description) ? description.trim() : null;
    }

    private BookCategoryResponse toResponse(BookCategory category) {
        return BookCategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .description(category.getDescription())
                .build();
    }
}


