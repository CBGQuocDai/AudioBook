package org.backend.book.repository;

import org.backend.book.entity.Book;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface BookRepository extends JpaRepository<Book, Long> {
	@Query("""
			select b from Book b
			where lower(b.name) like lower(concat('%', :keyword, '%'))
			   or lower(b.author) like lower(concat('%', :keyword, '%'))
			""")
	Page<Book> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);
}

