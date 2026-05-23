package org.backend.book.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldNameConstants;
import org.backend.file.entity.File;
import org.backend.common.entity.SoftDeleteEntity;

@Entity
@Table(name = "ebook_chapter")
@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldNameConstants
public class EbookChapter extends SoftDeleteEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @Column(name = "title")
    private String title;

    @Column(name = "chapter_number")
    private Integer chapterNumber;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "content_file_id")
    private File contentFile;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "audio_file_id")
    private File audioFile;
}
