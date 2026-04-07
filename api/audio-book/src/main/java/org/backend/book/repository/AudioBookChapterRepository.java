package org.backend.book.repository;

import org.backend.book.entity.AudioBookChapter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AudioBookChapterRepository extends JpaRepository<AudioBookChapter, Long> {
    Optional<AudioBookChapter> findByIdAndBookId(Long id, Long bookId);
}
