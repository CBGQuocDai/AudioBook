package org.backend.book.service;

import org.backend.book.dto.request.AdminBookSearchRequest;
import org.backend.book.dto.request.CreateBookRequest;
import org.backend.book.dto.request.UpdateBookRequest;
import org.backend.book.dto.response.BookDashboardResponse;
import org.backend.book.dto.response.BookResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface BookService {
	BookResponse createBook(CreateBookRequest request);

	BookResponse getBookById(Long id);

	Page<BookResponse> searchBooks(AdminBookSearchRequest request);

	Page<BookResponse> getTrendingBooks(Pageable pageable);

	Page<BookResponse> getNewArrivals(Pageable pageable);

	BookDashboardResponse getDashboard();

	BookResponse updateBook(Long id, UpdateBookRequest request);

	void deleteBook(Long id);
}


