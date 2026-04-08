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
@Table(name = "audio_progress")
@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldNameConstants
public class AudioProgress extends AbstractAuditingEntity<Long> {

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
    private AudioBookChapter chapter;

    @Column(name = "`current_time`")
    private Integer currentTime;

    @Column(name = "duration")
    private Integer duration;

    @Column(name = "progress_percent")
    private Float progressPercent;

    @Column(name = "playback_speed")
    private Float playbackSpeed;

    @Column(name = "is_playing")
    private Boolean isPlaying;

    @Column(name = "last_played_at")
    private LocalDateTime lastPlayedAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

