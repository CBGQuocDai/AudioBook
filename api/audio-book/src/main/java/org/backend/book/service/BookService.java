package org.backend.book.service;

import org.backend.book.dto.request.AdminBookSearchRequest;
import org.backend.book.dto.request.CreateBookRequest;
import org.backend.book.dto.request.UpdateBookRequest;
import org.backend.book.dto.response.BookResponse;
import org.springframework.data.domain.Page;

public interface BookService {
	BookResponse createBook(CreateBookRequest request);

	BookResponse getBookById(Long id);

	Page<BookResponse> searchBooks(AdminBookSearchRequest request);

	BookResponse updateBook(Long id, UpdateBookRequest request);

	void deleteBook(Long id);
}


