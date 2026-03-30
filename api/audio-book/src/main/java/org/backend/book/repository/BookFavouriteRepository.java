package org.backend.book.repository;

import io.lettuce.core.dynamic.annotation.Param;
import org.backend.book.entity.BookFavorite;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
@Repository
public interface BookFavouriteRepository extends JpaRepository<BookFavorite,Long> {
    @Query("""
    select bf
    from BookFavorite bf
    where bf.client.id = :clientId
    """)
    List<BookFavorite> findAllByClientId(@Param("clientId") Long clientId);

    @Query("""
    select count(bf) > 0
    from BookFavorite bf
    where bf.client.id = :clientId
      and bf.book.id = :bookId
    """)
    boolean existsByClientIdAndBookId(@Param("clientId") Long clientId,
                                      @Param("bookId") Long bookId);
    @Modifying
    @Query("""
    delete from BookFavorite bf
    where bf.client.id = :clientId
      and bf.book.id = :bookId
    """)
    void deleteByClientIdAndBookId(@Param("clientId") Long clientId,
                                   @Param("bookId") Long bookId);
}
