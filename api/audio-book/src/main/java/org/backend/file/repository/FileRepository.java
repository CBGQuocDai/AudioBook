package org.backend.file.repository;

import org.backend.file.entity.File;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository interface mapping persistent operations on {@link File} metadata records.
 */
@Repository
public interface FileRepository extends JpaRepository<File, Long> {
}

