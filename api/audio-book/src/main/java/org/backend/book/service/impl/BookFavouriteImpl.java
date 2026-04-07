package org.backend.book.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.response.BookResponse;
import org.backend.book.entity.Book;
import org.backend.book.entity.BookFavorite;
import org.backend.book.repository.BookFavouriteRepository;
import org.backend.book.repository.BookRepository;
import org.backend.book.service.BookFavouriteService;
import org.backend.client.entity.Client;
import org.backend.client.repository.ClientRepository;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.user.entity.User;
import org.backend.file.dto.FileDto;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BookFavouriteImpl implements BookFavouriteService {
    private final BookFavouriteRepository bookFavouriteRepository;
    private final BookRepository bookRepository;
    private final ClientRepository clientRepository;
    private Client getCurrentClient() {
        User user = (User) SecurityContextHolder.getContext()
                .getAuthentication()
                .getPrincipal();

        return clientRepository.findById(user.getId())
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }
    @Override
    @Transactional
    public void addFavourite(Long bookId) {

        Client client = getCurrentClient();

        if (bookFavouriteRepository.existsByClientIdAndBookId(client.getId(), bookId)) {
            return;
        }

        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new BusinessException(ErrorCode.BOOK_NOT_FOUND));

        BookFavorite favorite = BookFavorite.builder()
                .client(client)
                .book(book)
                .build();

        bookFavouriteRepository.save(favorite);
    }
    @Override
    @Transactional
    public void removeFavourite(Long bookId){
        Client client = getCurrentClient();
        bookFavouriteRepository.deleteByClientIdAndBookId(client.getId(), bookId);
    }
    @Override
    @Transactional
    public List<BookResponse> getMyFavourites(){
        Client client = getCurrentClient();
        List<BookFavorite> favorites = bookFavouriteRepository.findAllByClientId(client.getId());
        return favorites.stream()
                .map(fav -> {
                    Book book = fav.getBook();
                    return BookResponse.builder()
                            .id(book.getId())
                            .name(book.getName())
                            .author(book.getAuthor())
                            .coverFile(book.getCoverFile() == null ? null : new FileDto(book.getCoverFile()))
                            .build();
                })
                .toList();
    }
}
