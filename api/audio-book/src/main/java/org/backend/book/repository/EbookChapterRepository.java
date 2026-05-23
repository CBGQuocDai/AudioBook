package org.backend.book.repository;

import org.backend.book.entity.EbookChapter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface EbookChapterRepository extends JpaRepository<EbookChapter, Long> {
    Optional<EbookChapter> findByIdAndBookId(Long id, Long bookId);

    @Query("""
            select c from EbookChapter c
            join c.book b
            where lower(b.name) = lower(:bookName)
              and c.chapterNumber = :chapterNumber
            """)
    Optional<EbookChapter> findByBookNameAndChapterNumber(@Param("bookName") String bookName,
                                                          @Param("chapterNumber") Integer chapterNumber);

    @Query("""
            select c from EbookChapter c
            join c.book b
            where lower(b.name) = lower(:bookName)
              and lower(c.title) = lower(:chapterTitle)
            """)
    Optional<EbookChapter> findByBookNameAndChapterTitle(@Param("bookName") String bookName,
                                                         @Param("chapterTitle") String chapterTitle);
}
