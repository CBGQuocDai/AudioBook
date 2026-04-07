package org.backend.book.repository;

import org.backend.book.dto.response.BookTopPurchasedResponse;
import org.backend.book.entity.ClientBook;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ClientBookRepository extends JpaRepository<ClientBook, Long> {

    @Query("""
            select cb from ClientBook cb
            where cb.client.id = :clientId
            and cb.isActive = true
            order by cb.purchasedAt desc
            """)
    Page<ClientBook> findPurchasedBooks(@Param("clientId") Long clientId, Pageable pageable);

    @Query("""
            select case when count(cb) > 0 then true else false end
            from ClientBook cb
            where cb.client.id = :clientId
            and cb.book.id = :bookId
            and cb.isActive = true
            """)
    boolean isPurchased(@Param("clientId") Long clientId, @Param("bookId") Long bookId);

        @Query("""
    select new org.backend.book.dto.response.BookTopPurchasedResponse(
            b.id,
            b.name,
            b.author,
            b.coverFile,
            count(cb)
    )
    from ClientBook cb
    join cb.book b
    where cb.isActive = true
    group by b.id, b.name, b.author, b.coverFile
    order by count(cb) desc, b.id desc
    """)
    Page<BookTopPurchasedResponse> findTopPurchasedBooks(Pageable pageable);
}
