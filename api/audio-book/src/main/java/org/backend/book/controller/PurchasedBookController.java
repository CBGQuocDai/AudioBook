package org.backend.book.controller;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.response.PurchasedBookResponse;
import org.backend.book.service.PurchasedBookService;
import org.backend.common.response.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("purchased")
public class PurchasedBookController {
    private final PurchasedBookService purchasedBookService;

    @GetMapping
    public ApiResponse<Page<PurchasedBookResponse>> getPurchasedBooks(Pageable pageable) {
        return ApiResponse.<Page<PurchasedBookResponse>>builder()
                .data(purchasedBookService.getPurchasedBooks(pageable))
                .build();
    }

    @GetMapping("/check/{bookId}")
    public ApiResponse<Boolean> isPurchased(@PathVariable Long bookId) {
        return ApiResponse.<Boolean>builder()
                .data(purchasedBookService.isPurchased(bookId))
                .build();
    }

    @PostMapping("/{bookId}")
    public ApiResponse<PurchasedBookResponse> purchaseBook(@PathVariable Long bookId) {
        return ApiResponse.<PurchasedBookResponse>builder()
                .data(purchasedBookService.purchaseBook(bookId))
                .build();
    }
}
