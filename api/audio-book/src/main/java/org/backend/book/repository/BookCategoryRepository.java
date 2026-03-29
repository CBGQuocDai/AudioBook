package org.backend.book.repository;

import org.backend.book.entity.BookCategory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface BookCategoryRepository extends JpaRepository<BookCategory, Long> {

    @Query("""
            select c from BookCategory c
            where lower(c.name) like lower(concat('%', :keyword, '%'))
               or lower(c.description) like lower(concat('%', :keyword, '%'))
            """)
    Page<BookCategory> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);

    boolean existsByNameIgnoreCase(String name);

    boolean existsByNameIgnoreCaseAndIdNot(String name, Long id);
}


