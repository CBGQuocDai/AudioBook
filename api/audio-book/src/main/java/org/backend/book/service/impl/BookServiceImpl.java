package org.backend.book.service.impl;

import lombok.RequiredArgsConstructor;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.backend.book.dto.request.AdminBookSearchRequest;
import org.backend.book.dto.request.CreateBookRequest;
import org.backend.book.dto.request.CreateEbookChapterRequest;
import org.backend.book.dto.request.UpdateBookRequest;
import org.backend.book.dto.response.BookDashboardResponse;
import org.backend.book.dto.response.BookCategoryItemResponse;
import org.backend.book.dto.response.BookResponse;
import org.backend.book.dto.response.ChapterContentResponse;
import org.backend.book.dto.response.EbookChapterResponse;
import org.backend.book.dto.response.BookTopFavoriteResponse;
import org.backend.book.dto.response.BookTopPurchasedResponse;
import org.backend.book.entity.Book;
import org.backend.book.entity.BookCategory;
import org.backend.book.entity.BookCategoryMapping;
import org.backend.book.entity.EbookChapter;
import org.backend.book.repository.BookCategoryRepository;
import org.backend.book.repository.BookFavouriteRepository;
import org.backend.book.repository.BookRepository;
import org.backend.book.repository.ClientBookRepository;
import org.backend.book.repository.EbookChapterRepository;
import org.backend.book.service.BookService;
import org.backend.client.repository.ClientRepository;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.file.dto.FileDto;
import org.backend.file.entity.File;
import org.backend.file.enums.FileType;
import org.backend.file.repository.FileRepository;
import org.backend.file.service.FileService;
import org.backend.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BookServiceImpl implements BookService {

    private final BookRepository bookRepository;
    private final BookCategoryRepository bookCategoryRepository;
    private final BookFavouriteRepository bookFavouriteRepository;
    private final FileRepository fileRepository;
    private final ClientBookRepository clientBookRepository;
    private final ClientRepository clientRepository;
    private final EbookChapterRepository ebookChapterRepository;
    private final FileService fileService;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional
    public BookResponse createBook(CreateBookRequest request) {
        Book book = Book.builder().build();
        applyBookPayload(book, BookPayload.from(request));
        return toResponse(bookRepository.save(book));
    }

    @Override
    @Transactional(readOnly = true)
    public BookResponse getBookById(Long id) {
        Book book = findBookOrThrow(id);
        Long clientId = getCurrentClientIdSafe();
        int isRead = (clientId != null && clientBookRepository.isPurchased(clientId, id)) ? 1 : 0;
        return toResponse(book, isRead);
    }

    @Override
    @Transactional(readOnly = true)
    public ChapterContentResponse getChapterContent(String bookName, String chapter, String type) {
        EbookChapter ebookChapter = findChapterByBookAndChapter(bookName, chapter);

        String normalizedType = type == null ? "" : type.trim().toLowerCase();
        if ("audio".equals(normalizedType)) {
            File audioFile = ebookChapter.getAudioFile();
            return ChapterContentResponse.builder()
                    .bookName(ebookChapter.getBook().getName())
                    .chapterTitle(ebookChapter.getTitle())
                    .chapterNumber(ebookChapter.getChapterNumber())
                    .type("audio")
                    .audioPath(toPublicFilePath(audioFile))
                    .build();
        }
        if ("ebook".equals(normalizedType)) {
            return ChapterContentResponse.builder()
                    .bookName(ebookChapter.getBook().getName())
                    .chapterTitle(ebookChapter.getTitle())
                    .chapterNumber(ebookChapter.getChapterNumber())
                    .type("ebook")
                    .content(extractContent(fileService.readTextContent(ebookChapter.getContentFile())))
                    .build();
        }
        throw new BusinessException(ErrorCode.BOOK_INVALID_CHAPTER_CONTENT_TYPE);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<BookResponse> searchBooks(AdminBookSearchRequest request) {
        Pageable pageable = request.toPageable();
        String keyword = request.getKeyword();

        Page<Book> books = StringUtils.hasText(keyword)
                ? bookRepository.searchByKeyword(keyword.trim(), pageable)
                : bookRepository.findAll(pageable);

        return books.map(this::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<BookResponse> getTrendingBooks(Pageable pageable) {
        Page<Book> books = bookRepository.findTrendingBooks(pageable);
        return books.map(this::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<BookResponse> getNewArrivals(Pageable pageable) {
        Page<Book> books = bookRepository.findNewArrivals(pageable);
        return books.map(this::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public BookDashboardResponse getDashboard() {
        long totalBooks = bookRepository.count();
        List<BookTopFavoriteResponse> topFavoriteBooks = bookFavouriteRepository.findTopFavoriteBooks(PageRequest.of(0, 10));
        List<BookTopPurchasedResponse> topPurchasedBooks = clientBookRepository.findTopPurchasedBooks(PageRequest.of(0, 5)).getContent();

        return BookDashboardResponse.builder()
                .totalBooks(totalBooks)
                .topFavoriteBooks(topFavoriteBooks)
                .topPurchasedBooks(topPurchasedBooks)
                .build();
    }

    @Override
    @Transactional
    public BookResponse updateBook(Long id, UpdateBookRequest request) {
        Book book = findBookOrThrow(id);
        applyBookPayload(book, BookPayload.from(request));
        return toResponse(bookRepository.save(book));
    }

    @Override
    @Transactional
    public void deleteBook(Long id) {
        Book book = findBookOrThrow(id);
        bookRepository.delete(book);
    }

    private Book findBookOrThrow(Long id) {
        return bookRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.BOOK_NOT_FOUND));
    }

    private void applyBookPayload(Book book, BookPayload payload) {
        validateNoDuplicateEbookChapterNumbers(payload.ebookChapters());

        Set<Long> uniqueCategoryIds = validateAndNormalizeIds(payload.categoryIds(), ErrorCode.BOOK_INVALID_CATEGORY_IDS);
        List<BookCategory> categories = bookCategoryRepository.findAllById(uniqueCategoryIds);
        if (categories.size() != uniqueCategoryIds.size()) {
            throw new BusinessException(ErrorCode.BOOK_INVALID_CATEGORY_IDS);
        }

        Set<Long> requiredFileIds = collectRequiredFileIds(payload.coverFileId(), payload.ebookChapters());
        Map<Long, File> fileMap = loadFiles(requiredFileIds);

        validateCoverFile(payload.coverFileId(), fileMap);
        validateChapterFiles(payload.ebookChapters(), fileMap);

        book.setName(payload.name().trim());
        book.setAuthor(trimToNull(payload.author()));
        book.setDescription(trimToNull(payload.description()));
        book.setCoverFile(payload.coverFileId() == null ? null : fileMap.get(payload.coverFileId()));
        book.setCategories(buildCategoryMappings(book, categories));
        book.setEbookChapters(buildEbookChapters(book, payload.ebookChapters(), fileMap));
    }

    private record BookPayload(
            String name,
            String author,
            String description,
            Long coverFileId,
            List<Long> categoryIds,
            List<CreateEbookChapterRequest> ebookChapters) {

        private static BookPayload from(CreateBookRequest request) {
            return new BookPayload(
                    request.getName(),
                    request.getAuthor(),
                    request.getDescription(),
                    request.getCoverFileId(),
                    request.getCategoryIds(),
                    request.getEbookChapters());
        }

        private static BookPayload from(UpdateBookRequest request) {
            return new BookPayload(
                    request.getName(),
                    request.getAuthor(),
                    request.getDescription(),
                    request.getCoverFileId(),
                    request.getCategoryIds(),
                    request.getEbookChapters());
        }
    }

    private Set<Long> validateAndNormalizeIds(List<Long> ids, ErrorCode errorCode) {
        if (ids == null) {
            return Set.of();
        }

        Set<Long> unique = new LinkedHashSet<>();
        for (Long id : ids) {
            if (id == null || id <= 0 || !unique.add(id)) {
                throw new BusinessException(errorCode);
            }
        }
        return unique;
    }

    private Set<Long> collectRequiredFileIds(Long coverFileId,
                                             List<CreateEbookChapterRequest> ebookChapters) {
        Set<Long> fileIds = new HashSet<>();

        if (coverFileId != null) {
            fileIds.add(coverFileId);
        }

        ebookChapters.forEach(chapter -> {
            fileIds.add(chapter.getContentFileId());
            fileIds.add(chapter.getAudioFileId());
        });

        return fileIds;
    }

    private Map<Long, File> loadFiles(Set<Long> fileIds) {
        if (fileIds.isEmpty()) {
            return Map.of();
        }

        Map<Long, File> fileMap = fileRepository.findAllById(fileIds).stream()
                .collect(Collectors.toMap(File::getId, Function.identity()));

        if (fileMap.size() != fileIds.size()) {
            throw new BusinessException(ErrorCode.BOOK_INVALID_FILE_IDS);
        }

        return fileMap;
    }

    private void validateCoverFile(Long coverFileId, Map<Long, File> fileMap) {
        if (coverFileId == null) {
            return;
        }

        File coverFile = fileMap.get(coverFileId);
        FileType fileType = FileType.fromString(coverFile.getType());
        if (!FileType.isImageFile(fileType)) {
            throw new BusinessException(ErrorCode.BOOK_INVALID_COVER_FILE_TYPE);
        }
    }

    private void validateChapterFiles(List<CreateEbookChapterRequest> chapters, Map<Long, File> fileMap) {
        for (CreateEbookChapterRequest chapter : chapters) {
            File audioFile = fileMap.get(chapter.getAudioFileId());
            if (FileType.fromString(audioFile.getType()) != FileType.AUDIO) {
                throw new BusinessException(ErrorCode.BOOK_INVALID_AUDIO_FILE_TYPE);
            }
            File contentFile = fileMap.get(chapter.getContentFileId());
            if (FileType.fromString(contentFile.getType()) != FileType.DOCUMENT) {
                throw new BusinessException(ErrorCode.BOOK_INVALID_EBOOK_FILE_TYPE);
            }
        }
    }

    private List<BookCategoryMapping> buildCategoryMappings(Book book, List<BookCategory> categories) {
        List<BookCategoryMapping> mappings = new ArrayList<>();
        for (BookCategory category : categories) {
            mappings.add(BookCategoryMapping.builder()
                    .book(book)
                    .category(category)
                    .build());
        }
        return mappings;
    }

    private List<EbookChapter> buildEbookChapters(Book book,
                                                  List<CreateEbookChapterRequest> chapters,
                                                  Map<Long, File> fileMap) {
        List<EbookChapter> ebookChapters = new ArrayList<>();
        for (CreateEbookChapterRequest chapter : chapters) {
            ebookChapters.add(EbookChapter.builder()
                    .book(book)
                    .title(chapter.getTitle().trim())
                    .chapterNumber(chapter.getChapterNumber())
                    .durationSeconds(chapter.getDurationSeconds())
                    .contentFile(fileMap.get(chapter.getContentFileId()))
                    .audioFile(fileMap.get(chapter.getAudioFileId()))
                    .build());
        }
        return ebookChapters;
    }

    private void validateNoDuplicateEbookChapterNumbers(List<CreateEbookChapterRequest> chapters) {
        Set<Integer> chapterNumbers = new HashSet<>();

        for (CreateEbookChapterRequest item : chapters) {
            Integer chapterNumber = item.getChapterNumber();
            if (!chapterNumbers.add(chapterNumber)) {
                throw new BusinessException(ErrorCode.BOOK_EBOOK_CHAPTER_NUMBER_DUPLICATE);
            }
        }
    }

    private BookResponse toResponse(Book book) {
        return toResponse(book, 0);
    }

    private BookResponse toResponse(Book book, int isRead) {
        List<BookCategoryItemResponse> categories = book.getCategories() == null ? List.of() : book.getCategories().stream()
                .map(item -> BookCategoryItemResponse.builder()
                        .id(item.getCategory().getId())
                        .name(item.getCategory().getName())
                        .build())
                .toList();

        List<EbookChapterResponse> ebookChapters = book.getEbookChapters() == null ? List.of() : book.getEbookChapters().stream()
                .map(item -> EbookChapterResponse.builder()
                        .id(item.getId())
                        .title(item.getTitle())
                        .chapterNumber(item.getChapterNumber())
                        .durationSeconds(item.getDurationSeconds())
                        .contentFile(toFileDto(item.getContentFile()))
                        .audioFile(toFileDto(item.getAudioFile()))
                        .build())
                .toList();

        return BookResponse.builder()
                .id(book.getId())
                .name(book.getName())
                .author(book.getAuthor())
                .description(book.getDescription())
                .coverFile(book.getCoverFile() == null ? null : new FileDto(book.getCoverFile()))
                .categories(categories)
                .ebookChapters(ebookChapters)
                .isRead(isRead)
                .build();
    }

    /**
     * Lấy clientId của user đang đăng nhập.
     * Trả về null nếu chưa xác thực hoặc không phải client (ví dụ: admin vào xem sách).
     */
    private Long getCurrentClientIdSafe() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated()) return null;
            Object principal = auth.getPrincipal();
            if (!(principal instanceof User user)) return null;
            return clientRepository.findById(user.getId())
                    .map(c -> c.getId())
                    .orElse(null);
        } catch (Exception e) {
            return null;
        }
    }

    private FileDto toFileDto(File file) {
        return file == null ? null : new FileDto(file);
    }

    private String toPublicFilePath(File file) {
        if (file == null) {
            return null;
        }
        if (StringUtils.hasText(file.getFilePath()) && file.getFilePath().startsWith("http")) {
            return file.getFilePath();
        }
        return file.getFilePath();
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private EbookChapter findChapterByBookAndChapter(String bookName, String chapter) {
        String normalizedBookName = bookName.trim();
        String normalizedChapter = chapter.trim();
        try {
            return ebookChapterRepository
                    .findByBookNameAndChapterNumber(normalizedBookName, Integer.parseInt(normalizedChapter))
                    .orElseThrow(() -> new BusinessException(ErrorCode.EBOOK_CHAPTER_NOT_FOUND));
        } catch (NumberFormatException ignored) {
            return ebookChapterRepository
                    .findByBookNameAndChapterTitle(normalizedBookName, normalizedChapter)
                    .orElseThrow(() -> new BusinessException(ErrorCode.EBOOK_CHAPTER_NOT_FOUND));
        }
    }

    private String extractContent(String rawContent) {
        if (!StringUtils.hasText(rawContent)) {
            return "";
        }
        String trimmed = rawContent.trim();
        if (!trimmed.startsWith("{")) {
            return rawContent;
        }
        try {
            JsonNode root = objectMapper.readTree(trimmed);
            JsonNode content = root.get("content");
            return content == null || content.isNull() ? rawContent : content.asText();
        } catch (Exception ignored) {
            return rawContent;
        }
    }
}
