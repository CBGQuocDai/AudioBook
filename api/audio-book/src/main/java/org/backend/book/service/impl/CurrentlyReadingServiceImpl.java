package org.backend.book.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.response.CurrentlyReadingResponse;
import org.backend.book.entity.Book;
import org.backend.book.entity.EbookProgress;
import org.backend.book.repository.EbookProgressRepository;
import org.backend.book.service.CurrentlyReadingService;
import org.backend.client.entity.Client;
import org.backend.client.repository.ClientRepository;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.user.entity.User;
import org.backend.file.dto.FileDto;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CurrentlyReadingServiceImpl implements CurrentlyReadingService {

    private final EbookProgressRepository ebookProgressRepository;
    private final ClientRepository clientRepository;

    @Override
    @Transactional(readOnly = true)
    public Page<CurrentlyReadingResponse> getCurrentlyReading(Pageable pageable) {
        Client client = getCurrentClient();
        return ebookProgressRepository.findByClientIdOrderByLastReadAtDesc(client.getId(), pageable)
                .map(this::toResponse);
    }

    private Client getCurrentClient() {
        User user = (User) SecurityContextHolder.getContext()
                .getAuthentication()
                .getPrincipal();

        return clientRepository.findById(user.getId())
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }

    private CurrentlyReadingResponse toResponse(EbookProgress ebookProgress) {
        Book book = ebookProgress.getChapter().getBook();
        return CurrentlyReadingResponse.builder()
                .id(ebookProgress.getId())
                .bookId(book.getId())
                .bookName(book.getName())
                .bookAuthor(book.getAuthor())
                .coverFile(book.getCoverFile() == null ? null : new FileDto(book.getCoverFile()))
                .chapterId(ebookProgress.getChapter().getId())
                .chapterTitle(ebookProgress.getChapter().getTitle())
                .chapterNumber(ebookProgress.getChapter().getChapterNumber())
                .pageNumber(ebookProgress.getPageNumber())
                .offsetInPage(ebookProgress.getOffsetInPage())
                .progressPercent(ebookProgress.getProgressPercent())
                .lastReadAt(ebookProgress.getLastReadAt())
                .build();
    }
}
