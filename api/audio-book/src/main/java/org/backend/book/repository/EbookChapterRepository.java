package org.backend.book.repository;

import org.backend.book.entity.EbookChapter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface EbookChapterRepository extends JpaRepository<EbookChapter, Long> {
    Optional<EbookChapter> findByIdAndBookId(Long id, Long bookId);
}
