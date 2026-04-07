package org.backend.book.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.request.UpsertEbookProgressRequest;
import org.backend.book.dto.response.EbookProgressResponse;
import org.backend.book.entity.Book;
import org.backend.book.entity.EbookChapter;
import org.backend.book.entity.EbookProgress;
import org.backend.book.repository.BookRepository;
import org.backend.book.repository.EbookChapterRepository;
import org.backend.book.repository.EbookProgressRepository;
import org.backend.book.service.EbookProgressService;
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
public class EbookProgressServiceImpl implements EbookProgressService {

    private final EbookProgressRepository ebookProgressRepository;
    private final BookRepository bookRepository;
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
    public EbookProgressResponse upsertProgress(UpsertEbookProgressRequest request) {
        Client client = getCurrentClient();

        Book book = bookRepository.findById(request.getBookId())
                .orElseThrow(() -> new BusinessException(ErrorCode.BOOK_NOT_FOUND));

        EbookChapter chapter = ebookChapterRepository.findByIdAndBookId(request.getChapterId(), book.getId())
                .orElseThrow(() -> new BusinessException(ErrorCode.CHAPTER_NOT_BELONG_TO_BOOK));

        EbookProgress progress = ebookProgressRepository
                .findByClientIdAndBookId(client.getId(), book.getId())
                .orElse(EbookProgress.builder()
                        .client(client)
                        .book(book)
                        .build());

        progress.setChapter(chapter);
        progress.setPageNumber(request.getPageNumber());
        progress.setOffsetInPage(request.getOffsetInPage());
        progress.setProgressPercent(request.getProgressPercent());
        progress.setLastReadAt(LocalDateTime.now());
        progress.setUpdatedAt(LocalDateTime.now());

        EbookProgress saved = ebookProgressRepository.save(progress);
        return toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public EbookProgressResponse getProgressByBookId(Long bookId) {
        Client client = getCurrentClient();

        return ebookProgressRepository
                .findByClientIdAndBookId(client.getId(), bookId)
                .map(this::toResponse)
                .orElse(null);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<EbookProgressResponse> getMyRecentProgress(Pageable pageable) {
        Client client = getCurrentClient();
        return ebookProgressRepository
                .findByClientIdOrderByLastReadAtDesc(client.getId(), pageable)
                .map(this::toResponse);
    }

    private EbookProgressResponse toResponse(EbookProgress progress) {
        EbookChapter chapter = progress.getChapter();
        Book book = progress.getBook();

        return EbookProgressResponse.builder()
                .id(progress.getId())
                .pageNumber(progress.getPageNumber())
                .offsetInPage(progress.getOffsetInPage())
                .progressPercent(progress.getProgressPercent())
                .lastReadAt(progress.getLastReadAt())
                // Thông tin chương
                .chapterId(chapter.getId())
                .chapterTitle(chapter.getTitle())
                .chapterNumber(chapter.getChapterNumber())
                .chapterFile(chapter.getFile() == null ? null : new FileDto(chapter.getFile()))
                // Thông tin sách
                .bookId(book.getId())
                .bookName(book.getName())
                .bookAuthor(book.getAuthor())
                .bookCoverFile(book.getCoverFile() == null ? null : new FileDto(book.getCoverFile()))
                .build();
    }
}
