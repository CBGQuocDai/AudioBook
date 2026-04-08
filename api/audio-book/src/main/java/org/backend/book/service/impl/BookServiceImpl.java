package org.backend.book.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.book.dto.request.AdminBookSearchRequest;
import org.backend.book.dto.request.CreateAudioBookChapterRequest;
import org.backend.book.dto.request.CreateBookRequest;
import org.backend.book.dto.request.CreateEbookChapterRequest;
import org.backend.book.dto.request.UpdateBookRequest;
import org.backend.book.dto.response.BookDashboardResponse;
import org.backend.book.dto.response.AudioBookChapterResponse;
import org.backend.book.dto.response.BookCategoryItemResponse;
import org.backend.book.dto.response.BookResponse;
import org.backend.book.dto.response.EbookChapterResponse;
import org.backend.book.dto.response.BookTopFavoriteResponse;
import org.backend.book.dto.response.BookTopPurchasedResponse;
import org.backend.book.entity.AudioBookChapter;
import org.backend.book.entity.Book;
import org.backend.book.entity.BookCategory;
import org.backend.book.entity.BookCategoryMapping;
import org.backend.book.entity.BookDescriptionImage;
import org.backend.book.entity.EbookChapter;
import org.backend.book.repository.BookCategoryRepository;
import org.backend.book.repository.BookFavouriteRepository;
import org.backend.book.repository.BookRepository;
import org.backend.book.repository.ClientBookRepository;
import org.backend.book.service.BookService;
import org.backend.client.repository.ClientRepository;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.file.dto.FileDto;
import org.backend.file.entity.File;
import org.backend.file.enums.FileType;
import org.backend.file.repository.FileRepository;
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
        validateNoDuplicateAudioChapterNumbers(payload.audioChapters());

        Set<Long> uniqueCategoryIds = validateAndNormalizeIds(payload.categoryIds(), ErrorCode.BOOK_INVALID_CATEGORY_IDS);
        Set<Long> uniqueDescriptionImageIds = validateAndNormalizeIds(payload.descriptionImageFileIds(), ErrorCode.BOOK_INVALID_DESCRIPTION_IMAGE_IDS);

        List<BookCategory> categories = bookCategoryRepository.findAllById(uniqueCategoryIds);
        if (categories.size() != uniqueCategoryIds.size()) {
            throw new BusinessException(ErrorCode.BOOK_INVALID_CATEGORY_IDS);
        }

        Set<Long> requiredFileIds = collectRequiredFileIds(payload.coverFileId(), payload.ebookChapters(), payload.audioChapters(), uniqueDescriptionImageIds);
        Map<Long, File> fileMap = loadFiles(requiredFileIds);

        validateCoverFile(payload.coverFileId(), fileMap);
        validateAudioChapterFiles(payload.audioChapters(), fileMap);
        validateDescriptionImageFiles(uniqueDescriptionImageIds, fileMap);

        book.setName(payload.name().trim());
        book.setAuthor(trimToNull(payload.author()));
        book.setDescription(trimToNull(payload.description()));
        book.setCoverFile(payload.coverFileId() == null ? null : fileMap.get(payload.coverFileId()));
        book.setCategories(buildCategoryMappings(book, categories));
        book.setEbookChapters(buildEbookChapters(book, payload.ebookChapters(), fileMap));
        book.setAudioChapters(buildAudioChapters(book, payload.audioChapters(), fileMap));
        book.setDescriptionImages(buildDescriptionImages(book, uniqueDescriptionImageIds, fileMap));
    }

    private record BookPayload(
            String name,
            String author,
            String description,
            Long coverFileId,
            List<Long> categoryIds,
            List<CreateEbookChapterRequest> ebookChapters,
            List<CreateAudioBookChapterRequest> audioChapters,
            List<Long> descriptionImageFileIds) {

        private static BookPayload from(CreateBookRequest request) {
            return new BookPayload(
                    request.getName(),
                    request.getAuthor(),
                    request.getDescription(),
                    request.getCoverFileId(),
                    request.getCategoryIds(),
                    request.getEbookChapters(),
                    request.getAudioChapters(),
                    request.getDescriptionImageFileIds());
        }

        private static BookPayload from(UpdateBookRequest request) {
            return new BookPayload(
                    request.getName(),
                    request.getAuthor(),
                    request.getDescription(),
                    request.getCoverFileId(),
                    request.getCategoryIds(),
                    request.getEbookChapters(),
                    request.getAudioChapters(),
                    request.getDescriptionImageFileIds());
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
                                             List<CreateEbookChapterRequest> ebookChapters,
                                             List<CreateAudioBookChapterRequest> audioChapters,
                                             Set<Long> descriptionImageIds) {
        Set<Long> fileIds = new HashSet<>();

        if (coverFileId != null) {
            fileIds.add(coverFileId);
        }

        ebookChapters.forEach(chapter -> fileIds.add(chapter.getFileId()));
        audioChapters.forEach(chapter -> fileIds.add(chapter.getFileId()));
        fileIds.addAll(descriptionImageIds);

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

    private void validateAudioChapterFiles(List<CreateAudioBookChapterRequest> chapters, Map<Long, File> fileMap) {
        for (CreateAudioBookChapterRequest chapter : chapters) {
            File file = fileMap.get(chapter.getFileId());
            if (FileType.fromString(file.getType()) != FileType.AUDIO) {
                throw new BusinessException(ErrorCode.BOOK_INVALID_AUDIO_FILE_TYPE);
            }
        }
    }

    private void validateDescriptionImageFiles(Set<Long> imageFileIds, Map<Long, File> fileMap) {
        for (Long imageFileId : imageFileIds) {
            File file = fileMap.get(imageFileId);
            FileType fileType = FileType.fromString(file.getType());
            if (!FileType.isImageFile(fileType)) {
                throw new BusinessException(ErrorCode.BOOK_INVALID_DESCRIPTION_IMAGE_FILE_TYPE);
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
                    .file(fileMap.get(chapter.getFileId()))
                    .build());
        }
        return ebookChapters;
    }

    private List<AudioBookChapter> buildAudioChapters(Book book,
                                                      List<CreateAudioBookChapterRequest> chapters,
                                                      Map<Long, File> fileMap) {
        List<AudioBookChapter> audioChapters = new ArrayList<>();
        for (CreateAudioBookChapterRequest chapter : chapters) {
            audioChapters.add(AudioBookChapter.builder()
                    .book(book)
                    .title(chapter.getTitle().trim())
                    .chapterNumber(chapter.getChapterNumber())
                    .durationSeconds(chapter.getDurationSeconds())
                    .file(fileMap.get(chapter.getFileId()))
                    .build());
        }
        return audioChapters;
    }

    private List<BookDescriptionImage> buildDescriptionImages(Book book,
                                                              Set<Long> imageFileIds,
                                                              Map<Long, File> fileMap) {
        List<BookDescriptionImage> images = new ArrayList<>();
        for (Long imageFileId : imageFileIds) {
            images.add(BookDescriptionImage.builder()
                    .book(book)
                    .file(fileMap.get(imageFileId))
                    .build());
        }
        return images;
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

    private void validateNoDuplicateAudioChapterNumbers(List<CreateAudioBookChapterRequest> chapters) {
        Set<Integer> chapterNumbers = new HashSet<>();

        for (CreateAudioBookChapterRequest item : chapters) {
            Integer chapterNumber = item.getChapterNumber();
            if (!chapterNumbers.add(chapterNumber)) {
                throw new BusinessException(ErrorCode.BOOK_AUDIO_CHAPTER_NUMBER_DUPLICATE);
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
                        .file(toFileDto(item.getFile()))
                        .build())
                .toList();

        List<AudioBookChapterResponse> audioChapters = book.getAudioChapters() == null ? List.of() : book.getAudioChapters().stream()
                .map(item -> AudioBookChapterResponse.builder()
                        .id(item.getId())
                        .title(item.getTitle())
                        .chapterNumber(item.getChapterNumber())
                        .durationSeconds(item.getDurationSeconds())
                        .file(toFileDto(item.getFile()))
                        .build())
                .toList();

        List<FileDto> descriptionImages = book.getDescriptionImages() == null ? List.of() : book.getDescriptionImages().stream()
                .map(BookDescriptionImage::getFile)
                .filter(file -> file != null)
                .map(FileDto::new)
                .toList();

        return BookResponse.builder()
                .id(book.getId())
                .name(book.getName())
                .author(book.getAuthor())
                .description(book.getDescription())
                .coverFile(book.getCoverFile() == null ? null : new FileDto(book.getCoverFile()))
                .categories(categories)
                .ebookChapters(ebookChapters)
                .audioChapters(audioChapters)
                .descriptionImages(descriptionImages)
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

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }
}


