-- ====================================================================
-- AudioBook API Database Schema
-- Database: audio_book
-- Script Date: 2026-03-28
-- ====================================================================

-- Drop existing tables (if needed for fresh setup)
-- DROP TABLE IF EXISTS credit_transaction;
-- DROP TABLE IF EXISTS payment_transaction;
-- DROP TABLE IF EXISTS ebook_progress;
-- DROP TABLE IF EXISTS audio_progress;
-- DROP TABLE IF EXISTS bookmark;
-- DROP TABLE IF EXISTS book_favorite;
-- DROP TABLE IF EXISTS client_book;
-- DROP TABLE IF EXISTS book_description_image;
-- DROP TABLE IF EXISTS book_category_mapping;
-- DROP TABLE IF EXISTS ebook_chapter;
-- DROP TABLE IF EXISTS book_category;
-- DROP TABLE IF EXISTS book;
-- DROP TABLE IF EXISTS `file`;
-- DROP TABLE IF EXISTS client;
-- DROP TABLE IF EXISTS admin;
-- DROP TABLE IF EXISTS `users`;

-- ====================================================================
-- 1. File Table
-- ====================================================================
CREATE TABLE `file` (
                        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                        file_name VARCHAR(255),
                        file_path VARCHAR(500),
                        url VARCHAR(1000),
                        `type` VARCHAR(50),
                        created_by VARCHAR(50),
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        last_modified_by VARCHAR(50),
                        last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        INDEX idx_file_name (file_name),
                        INDEX idx_file_type (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 2. Users Table (Base User Entity - JOINED inheritance strategy)
-- ====================================================================
CREATE TABLE `users` (
                         id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                         password VARCHAR(255) NOT NULL,
                         name VARCHAR(255) NOT NULL,
                         email VARCHAR(255) NOT NULL UNIQUE,
                         wallet VARCHAR(255),
                         active TINYINT(1) DEFAULT 1,
                         role VARCHAR(50) NOT NULL DEFAULT 'USER',
                         avatar_file_id BIGINT,
                         created_by VARCHAR(50),
                         created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                         last_modified_by VARCHAR(50),
                         last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                         is_deleted TINYINT DEFAULT 0,
                         FOREIGN KEY (avatar_file_id) REFERENCES `file`(id) ON DELETE SET NULL,
                         INDEX idx_email (email),
                         INDEX idx_avatar_file_id (avatar_file_id),
                         INDEX idx_role (role),
                         INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 3. Admin Table (Extended User - JOINED inheritance)
-- ====================================================================
CREATE TABLE admin (
                       user_id BIGINT NOT NULL PRIMARY KEY,
                       FOREIGN KEY (user_id) REFERENCES `users`(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 4. Client Table (Extended User - JOINED inheritance)
-- ====================================================================
CREATE TABLE client (
                        user_id BIGINT NOT NULL PRIMARY KEY,
                        avatar_path VARCHAR(255),
                        total_credit INT DEFAULT 0,
                        FOREIGN KEY (user_id) REFERENCES `users`(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 5. Book Table
-- ====================================================================
CREATE TABLE book (
                      id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                      name VARCHAR(255) NOT NULL,
                      author VARCHAR(255),
                      description LONGTEXT,
                      cover_file_id BIGINT,
                      created_by VARCHAR(50),
                      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                      last_modified_by VARCHAR(50),
                      last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                      is_deleted TINYINT DEFAULT 0,
                      FOREIGN KEY (cover_file_id) REFERENCES `file`(id) ON DELETE SET NULL,
                      INDEX idx_name (name),
                      INDEX idx_author (author),
                      INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 6. Book Category Table
-- ====================================================================
CREATE TABLE book_category (
                               id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                               name VARCHAR(255) NOT NULL UNIQUE,
                               description LONGTEXT,
                               created_by VARCHAR(50),
                               created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                               last_modified_by VARCHAR(50),
                               last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                               is_deleted TINYINT DEFAULT 0,
                               INDEX idx_name (name),
                               INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 7. Book Category Mapping Table (Many-to-Many)
-- ====================================================================
CREATE TABLE book_category_mapping (
                                       id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                       book_id BIGINT NOT NULL,
                                       book_category_id BIGINT NOT NULL,
                                       created_by VARCHAR(50),
                                       created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                                       last_modified_by VARCHAR(50),
                                       last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                       FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
                                       FOREIGN KEY (book_category_id) REFERENCES book_category(id) ON DELETE CASCADE,
                                       UNIQUE KEY unique_book_category (book_id, book_category_id),
                                       INDEX idx_book_id (book_id),
                                       INDEX idx_category_id (book_category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 8. Ebook Chapter Table
-- ====================================================================
CREATE TABLE ebook_chapter (
                               id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                               book_id BIGINT NOT NULL,
                               title VARCHAR(255),
                               chapter_number INT,
                               duration_seconds INT,
                               content_file_id BIGINT,
                               audio_file_id BIGINT,
                               created_by VARCHAR(50),
                               created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                               last_modified_by VARCHAR(50),
                               last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                               is_deleted TINYINT DEFAULT 0,
                               FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
                               FOREIGN KEY (content_file_id) REFERENCES `file`(id) ON DELETE SET NULL,
                               FOREIGN KEY (audio_file_id) REFERENCES `file`(id) ON DELETE SET NULL,
                               UNIQUE KEY unique_book_chapter_number (book_id, chapter_number),
                               INDEX idx_book_id (book_id),
                               INDEX idx_chapter_number (chapter_number),
                               INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 10. Book Description Image Table
-- ====================================================================
CREATE TABLE book_description_image (
                                        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                        book_id BIGINT NOT NULL,
                                        file_id BIGINT NOT NULL,
                                        created_by VARCHAR(50),
                                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                                        last_modified_by VARCHAR(50),
                                        last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                        FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
                                        FOREIGN KEY (file_id) REFERENCES `file`(id) ON DELETE CASCADE,
                                        INDEX idx_book_id (book_id),
                                        INDEX idx_file_id (file_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 11. Client Book Table (Purchase/Access record)
-- ====================================================================
CREATE TABLE client_book (
                             id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                             user_id BIGINT NOT NULL,
                             book_id BIGINT NOT NULL,
                             purchased_at DATETIME,
                             is_active TINYINT(1) DEFAULT 1,
                             expired TINYINT(1) DEFAULT 0,
                             created_by VARCHAR(50),
                             created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                             last_modified_by VARCHAR(50),
                             last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                             is_deleted TINYINT DEFAULT 0,
                             FOREIGN KEY (user_id) REFERENCES client(user_id) ON DELETE CASCADE,
                             FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
                             UNIQUE KEY unique_user_book (user_id, book_id),
                             INDEX idx_user_id (user_id),
                             INDEX idx_book_id (book_id),
                             INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 12. Bookmark Table
-- ====================================================================
CREATE TABLE bookmark (
                          id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                          user_id BIGINT NOT NULL,
                          book_id BIGINT NOT NULL,
                          note LONGTEXT,
                          created_by VARCHAR(50),
                          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                          last_modified_by VARCHAR(50),
                          last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                          is_deleted TINYINT DEFAULT 0,
                          FOREIGN KEY (user_id) REFERENCES client(user_id) ON DELETE CASCADE,
                          FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
                          INDEX idx_user_id (user_id),
                          INDEX idx_book_id (book_id),
                          INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 13. Book Favorite Table
-- ====================================================================
CREATE TABLE book_favorite (
                               id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                               user_id BIGINT NOT NULL,
                               book_id BIGINT NOT NULL,
                               created_by VARCHAR(50),
                               created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                               last_modified_by VARCHAR(50),
                               last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                               FOREIGN KEY (user_id) REFERENCES client(user_id) ON DELETE CASCADE,
                               FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
                               UNIQUE KEY unique_user_book_favorite (user_id, book_id),
                               INDEX idx_user_id (user_id),
                               INDEX idx_book_id (book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 14. Audio Progress Table
-- ====================================================================
CREATE TABLE audio_progress (
                                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                user_id BIGINT NOT NULL,
                                book_id BIGINT NOT NULL,
                                chapter_id BIGINT NOT NULL,
                                `current_time` INT DEFAULT 0,
                                duration INT,
                                progress_percent FLOAT DEFAULT 0,
                                playback_speed FLOAT DEFAULT 1.0,
                                is_playing TINYINT(1) DEFAULT 0,
                                last_played_at DATETIME,
                                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                created_by VARCHAR(50),
                                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                                last_modified_by VARCHAR(50),
                                last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                FOREIGN KEY (user_id) REFERENCES client(user_id) ON DELETE CASCADE,
                                FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
                                FOREIGN KEY (chapter_id) REFERENCES ebook_chapter(id) ON DELETE CASCADE,
                                UNIQUE KEY unique_user_chapter (user_id, chapter_id),
                                INDEX idx_user_id (user_id),
                                INDEX idx_book_id (book_id),
                                INDEX idx_chapter_id (chapter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 15. Ebook Progress Table
-- ====================================================================
CREATE TABLE ebook_progress (
                                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                user_id BIGINT NOT NULL,
                                book_id BIGINT NOT NULL,
                                chapter_id BIGINT NOT NULL,
                                page_number INT DEFAULT 0,
                                offset_in_page FLOAT DEFAULT 0,
                                progress_percent FLOAT DEFAULT 0,
                                last_read_at DATETIME,
                                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                created_by VARCHAR(50),
                                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                                last_modified_by VARCHAR(50),
                                last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                FOREIGN KEY (user_id) REFERENCES client(user_id) ON DELETE CASCADE,
                                FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
                                FOREIGN KEY (chapter_id) REFERENCES ebook_chapter(id) ON DELETE CASCADE,
                                UNIQUE KEY unique_user_chapter (user_id, chapter_id),
                                INDEX idx_user_id (user_id),
                                INDEX idx_book_id (book_id),
                                INDEX idx_chapter_id (chapter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- 16. Payment Transaction Table (Stripe backend-first)
-- ====================================================================
CREATE TABLE IF NOT EXISTS payment_transaction (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    payment_code VARCHAR(64) NOT NULL,
    order_id VARCHAR(128) NOT NULL,
    user_id VARCHAR(128) NOT NULL,
    provider VARCHAR(20) NOT NULL,
    method VARCHAR(20) NOT NULL,
    amount BIGINT NOT NULL,
    currency VARCHAR(10) NOT NULL,
    status VARCHAR(30) NOT NULL,
    stripe_payment_intent_id VARCHAR(128),
    stripe_client_secret VARCHAR(255),
    request_token TEXT,
    idempotency_key VARCHAR(128) NOT NULL,
    failure_reason VARCHAR(500),
    created_by VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(50),
    last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_payment_transaction_payment_code (payment_code),
    UNIQUE KEY uk_payment_transaction_idempotency_key (idempotency_key),
    UNIQUE KEY uk_payment_transaction_stripe_intent (stripe_payment_intent_id),
    INDEX idx_payment_transaction_order_id (order_id),
    INDEX idx_payment_transaction_user_id (user_id),
    INDEX idx_payment_transaction_status (status),
    INDEX idx_payment_transaction_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- Indexes for Performance Optimization
-- ====================================================================

ALTER TABLE book ADD INDEX idx_created_at (created_at);
ALTER TABLE ebook_chapter ADD INDEX idx_content_file_id (content_file_id);
ALTER TABLE ebook_chapter ADD INDEX idx_audio_file_id (audio_file_id);
ALTER TABLE `users` ADD INDEX idx_created_at (created_at);

-- ====================================================================
-- End of Database Schema
-- ====================================================================
