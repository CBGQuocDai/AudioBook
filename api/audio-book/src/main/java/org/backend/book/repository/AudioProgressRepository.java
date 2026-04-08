package org.backend.book.repository;

import org.backend.book.entity.AudioProgress;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AudioProgressRepository extends JpaRepository<AudioProgress, Long> {

    @Query("""
            select ap from AudioProgress ap
            where ap.client.id = :clientId
            and ap.book.id = :bookId
            """)
    Optional<AudioProgress> findByClientIdAndBookId(@Param("clientId") Long clientId, @Param("bookId") Long bookId);

    @Query("""
            select ap from AudioProgress ap
            where ap.client.id = :clientId
            order by ap.lastPlayedAt desc
            """)
    Page<AudioProgress> findByClientIdOrderByLastPlayedAtDesc(@Param("clientId") Long clientId, Pageable pageable);
}
