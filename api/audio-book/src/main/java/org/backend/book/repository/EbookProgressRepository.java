package org.backend.book.repository;

import org.backend.book.entity.EbookProgress;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface EbookProgressRepository extends JpaRepository<EbookProgress, Long> {

    @Query("""
            select ep from EbookProgress ep
            where ep.client.id = :clientId
            and ep.book.id = :bookId
            """)
    Optional<EbookProgress> findByClientIdAndBookId(@Param("clientId") Long clientId, @Param("bookId") Long bookId);

    @Query("""
            select ep from EbookProgress ep
            where ep.client.id = :clientId
            order by ep.lastReadAt desc
            """)
    Page<EbookProgress> findByClientIdOrderByLastReadAtDesc(@Param("clientId") Long clientId, Pageable pageable);
}

