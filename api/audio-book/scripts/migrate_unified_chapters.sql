-- Migrate existing split audio/ebook chapter tables into ebook_chapter.
-- Run against MySQL after backing up the database.

SET FOREIGN_KEY_CHECKS = 0;

SET @fk := (
    SELECT constraint_name
    FROM information_schema.key_column_usage
    WHERE table_schema = DATABASE()
      AND table_name = 'audio_progress'
      AND column_name = 'chapter_id'
      AND referenced_table_name = 'audio_book_chapter'
    LIMIT 1
);
SET @sql := IF(@fk IS NULL, 'SELECT 1', CONCAT('ALTER TABLE audio_progress DROP FOREIGN KEY ', @fk));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @fk := (
    SELECT constraint_name
    FROM information_schema.key_column_usage
    WHERE table_schema = DATABASE()
      AND table_name = 'ebook_chapter'
      AND column_name = 'file_id'
      AND referenced_table_name = 'file'
    LIMIT 1
);
SET @sql := IF(@fk IS NULL, 'SELECT 1', CONCAT('ALTER TABLE ebook_chapter DROP FOREIGN KEY ', @fk));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ebook_chapter' AND column_name = 'duration_seconds');
SET @sql := IF(@exists = 0, 'ALTER TABLE ebook_chapter ADD COLUMN duration_seconds INT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ebook_chapter' AND column_name = 'content_file_id');
SET @sql := IF(@exists = 0, 'ALTER TABLE ebook_chapter ADD COLUMN content_file_id BIGINT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ebook_chapter' AND column_name = 'audio_file_id');
SET @sql := IF(@exists = 0, 'ALTER TABLE ebook_chapter ADD COLUMN audio_file_id BIGINT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE ebook_chapter
SET content_file_id = COALESCE(content_file_id, file_id)
WHERE content_file_id IS NULL;

UPDATE ebook_chapter ec
JOIN audio_book_chapter ac
  ON ac.book_id = ec.book_id AND ac.chapter_number = ec.chapter_number
SET ec.audio_file_id = COALESCE(ec.audio_file_id, ac.file_id),
    ec.duration_seconds = COALESCE(ec.duration_seconds, ac.duration_seconds);

UPDATE audio_progress ap
JOIN audio_book_chapter ac ON ac.id = ap.chapter_id
JOIN ebook_chapter ec ON ec.book_id = ac.book_id AND ec.chapter_number = ac.chapter_number
SET ap.chapter_id = ec.id;

SET @exists := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ebook_chapter' AND column_name = 'file_id');
SET @sql := IF(@exists = 1, 'ALTER TABLE ebook_chapter DROP COLUMN file_id', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS audio_book_chapter;

ALTER TABLE ebook_chapter
    ADD CONSTRAINT fk_ebook_chapter_content_file FOREIGN KEY (content_file_id) REFERENCES `file`(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_ebook_chapter_audio_file FOREIGN KEY (audio_file_id) REFERENCES `file`(id) ON DELETE SET NULL;

ALTER TABLE audio_progress
    ADD CONSTRAINT fk_audio_progress_chapter FOREIGN KEY (chapter_id) REFERENCES ebook_chapter(id) ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;
