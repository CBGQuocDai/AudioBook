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

	@Query("""
    select b from Book b
    left join BookFavorite bf on b = bf.book
    group by b
    order by count(distinct bf.id) desc, b.id desc
""")
	Page<Book> findTrendingBooks(Pageable pageable);

	@Query("""
			select b from Book b
			order by b.createdAt desc
			""")
	Page<Book> findNewArrivals(Pageable pageable);
}

