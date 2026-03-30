package org.backend.book.service;

import org.backend.book.dto.response.PurchasedBookResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface PurchasedBookService {
    
    Page<PurchasedBookResponse> getPurchasedBooks(Pageable pageable);
    
    boolean isPurchased(Long bookId);
    
    PurchasedBookResponse purchaseBook(Long bookId);
}
