package org.backend.book.service;

import org.backend.book.dto.response.BookResponse;
import org.backend.book.entity.BookFavorite;

import java.util.List;

public interface BookFavouriteService {
    void addFavourite(Long bookId);
    void removeFavourite(Long bookId);
    List<BookResponse> getMyFavourites();
}
