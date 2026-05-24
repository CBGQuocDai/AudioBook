package org.backend.book.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.request.UpsertAudioProgressRequest;
import org.backend.book.dto.response.AudioProgressResponse;
import org.backend.book.entity.AudioProgress;
import org.backend.book.entity.Book;
import org.backend.book.entity.EbookChapter;
import org.backend.book.repository.AudioProgressRepository;
import org.backend.book.repository.EbookChapterRepository;
import org.backend.book.service.AudioProgressService;
import org.backend.client.entity.Client;
import org.backend.client.repository.ClientRepository;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.file.dto.FileDto;
import org.backend.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AudioProgressServiceImpl implements AudioProgressService {

    private final AudioProgressRepository audioProgressRepository;
    private final EbookChapterRepository ebookChapterRepository;
    private final ClientRepository clientRepository;

    private Client getCurrentClient() {
        User user = (User) SecurityContextHolder.getContext()
                .getAuthentication()
                .getPrincipal();
        return clientRepository.findById(user.getId())
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }

    @Override
    @Transactional
    public AudioProgressResponse upsertProgress(UpsertAudioProgressRequest request) {
        Client client = getCurrentClient();

        EbookChapter chapter = ebookChapterRepository.findByIdAndBookId(request.getChapterId(), request.getBookId())
                .orElseThrow(() -> new BusinessException(ErrorCode.CHAPTER_NOT_BELONG_TO_BOOK));

        AudioProgress progress = audioProgressRepository
                .findByClientIdAndBookId(client.getId(), request.getBookId())
                .orElse(AudioProgress.builder()
                        .client(client)
                        .build());

        progress.setChapter(chapter);
        progress.setCurrentTime(request.getCurrentTime());
        progress.setDuration(request.getDuration());
        progress.setProgressPercent(request.getProgressPercent());
        progress.setPlaybackSpeed(request.getPlaybackSpeed() != null ? request.getPlaybackSpeed() : 1.0f);
        progress.setIsPlaying(false);
        progress.setLastPlayedAt(LocalDateTime.now());
        progress.setUpdatedAt(LocalDateTime.now());

        AudioProgress saved = audioProgressRepository.save(progress);
        return toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public AudioProgressResponse getProgressByBookId(Long bookId) {
        Client client = getCurrentClient();

        return audioProgressRepository
                .findByClientIdAndBookId(client.getId(), bookId)
                .map(this::toResponse)
                .orElse(null);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<AudioProgressResponse> getMyRecentProgress(Pageable pageable) {
        Client client = getCurrentClient();
        return audioProgressRepository
                .findByClientIdOrderByLastPlayedAtDesc(client.getId(), pageable)
                .map(this::toResponse);
    }

    private AudioProgressResponse toResponse(AudioProgress progress) {
        EbookChapter chapter = progress.getChapter();
        Book book = chapter.getBook();

        return AudioProgressResponse.builder()
                .id(progress.getId())
                .currentTime(progress.getCurrentTime())
                .duration(progress.getDuration())
                .progressPercent(progress.getProgressPercent())
                .playbackSpeed(progress.getPlaybackSpeed())
                .lastPlayedAt(progress.getLastPlayedAt())
                // Thông tin chương
                .chapterId(chapter.getId())
                .chapterTitle(chapter.getTitle())
                .chapterNumber(chapter.getChapterNumber())
                .chapterDurationSeconds(chapter.getDurationSeconds())
                .chapterFile(chapter.getAudioFile() == null ? null : new FileDto(chapter.getAudioFile()))
                // Thông tin sách
                .bookId(book.getId())
                .bookName(book.getName())
                .bookAuthor(book.getAuthor())
                .bookCoverFile(book.getCoverFile() == null ? null : new FileDto(book.getCoverFile()))
                .build();
    }
}
