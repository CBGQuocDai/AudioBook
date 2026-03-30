package org.backend.book.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.response.PurchasedBookResponse;
import org.backend.book.entity.ClientBook;
import org.backend.book.entity.Book;
import org.backend.book.repository.ClientBookRepository;
import org.backend.book.repository.BookRepository;
import org.backend.book.service.PurchasedBookService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.user.entity.Client;
import org.backend.user.entity.User;
import org.backend.user.repository.ClientRepository;
import org.backend.file.dto.FileDto;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class PurchasedBookServiceImpl implements PurchasedBookService {

    private final ClientBookRepository clientBookRepository;
    private final BookRepository bookRepository;
    private final ClientRepository clientRepository;

    @Override
    @Transactional(readOnly = true)
    public Page<PurchasedBookResponse> getPurchasedBooks(Pageable pageable) {
        Client client = getCurrentClient();
        return clientBookRepository.findPurchasedBooks(client.getId(), pageable)
                .map(this::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isPurchased(Long bookId) {
        Client client = getCurrentClient();
        return clientBookRepository.isPurchased(client.getId(), bookId);
    }

    @Override
    @Transactional
    public PurchasedBookResponse purchaseBook(Long bookId) {
        Client client = getCurrentClient();
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new BusinessException(ErrorCode.BOOK_NOT_FOUND));

        if (clientBookRepository.isPurchased(client.getId(), bookId)) {
            throw new BusinessException(ErrorCode.USER_EXIST);
        }

        ClientBook clientBook = ClientBook.builder()
                .client(client)
                .book(book)
                .purchasedAt(LocalDateTime.now())
                .isActive(true)
                .expired(false)
                .build();

        return toResponse(clientBookRepository.save(clientBook));
    }

    private Client getCurrentClient() {
        User user = (User) SecurityContextHolder.getContext()
                .getAuthentication()
                .getPrincipal();

        return clientRepository.findById(user.getId())
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }

    private PurchasedBookResponse toResponse(ClientBook clientBook) {
        return PurchasedBookResponse.builder()
                .id(clientBook.getId())
                .bookId(clientBook.getBook().getId())
                .bookName(clientBook.getBook().getName())
                .bookAuthor(clientBook.getBook().getAuthor())
                .coverFile(clientBook.getBook().getCoverFile() == null ? null : new FileDto(clientBook.getBook().getCoverFile()))
                .purchasedAt(clientBook.getPurchasedAt())
                .isActive(clientBook.getIsActive())
                .expired(clientBook.getExpired())
                .build();
    }
}
