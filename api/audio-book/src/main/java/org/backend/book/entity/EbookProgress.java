package org.backend.book.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldNameConstants;
import org.backend.common.entity.AbstractAuditingEntity;
import org.backend.client.entity.Client;
import org.hibernate.annotations.Fetch;
import org.hibernate.annotations.FetchMode;

import java.time.LocalDateTime;

@Entity
@Table(name = "ebook_progress")
@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldNameConstants
public class EbookProgress extends AbstractAuditingEntity<Long> {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @Fetch(FetchMode.SELECT)
    @JoinColumn(name = "user_id", nullable = false)
    private Client client;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "chapter_id", nullable = false)
    private EbookChapter chapter;

    @Column(name = "page_number")
    private Integer pageNumber;

    @Column(name = "offset_in_page")
    private Float offsetInPage;

    @Column(name = "progress_percent")
    private Float progressPercent;

    @Column(name = "last_read_at")
    private LocalDateTime lastReadAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
