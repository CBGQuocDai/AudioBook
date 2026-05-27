import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/components/book_detail/services/book_detail_api_service.dart';

import '../model/reading_chapter_model.dart';
import '../model/reading_route_args.dart';
import '../repository/reading_repository.dart';
import '../services/reading_pdf_service.dart';

/// Provider quản lý trạng thái và logic của màn hình đọc sách (Ebook).
class ReadingProvider extends ChangeNotifier {
  ReadingProvider({
    ReadingRepository? repository,
  }) : _repository = repository ?? ReadingRepositoryImpl();

  final ReadingRepository _repository;
  final TokenStorageService _tokenStorage = TokenStorageService();

  int _bookId = 0;
  int get bookId => _bookId;
  String _bookName = '';
  String get bookName => _bookName;
  bool _isReadMode = true;
  bool get isReadMode => _isReadMode;
  bool get isLockedMode => !_isReadMode;

  bool _forceLockedPrompt = false;
  bool get forceLockedPrompt => _forceLockedPrompt;

  int _maxUnlockedChapterIndex = 0;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ReadingChapterModel> _chapters = const [];
  List<ReadingChapterModel> get chapters => _chapters;

  int _chapterIndex = 0;
  int get chapterIndex => _chapterIndex;

  ReadingChapterModel? get currentChapter {
    if (_chapters.isEmpty || _chapterIndex < 0 || _chapterIndex >= _chapters.length) {
      return null;
    }
    return _chapters[_chapterIndex];
  }

  // Remove cached PDF path; we now read text pages.
  List<String> _pageTexts = const [];
  List<String> get pageTexts => _pageTexts;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  ScrollController? _scrollController;
  ScrollController? get scrollController => _scrollController;

  int _initialPage = 0;
  int get initialPage => _initialPage;

  int? _pendingScrollPage;

  double _scrollProgress = 0.0;
  double get progress {
    if (_totalPages <= 0) {
      return 0;
    }
    return _scrollProgress.clamp(0.0, 1.0);
  }

  bool _isFavourite = false;
  bool get isFavourite => _isFavourite;

  bool _isFavouriteLoading = false;
  bool get isFavouriteLoading => _isFavouriteLoading;

  /// Khởi tạo dữ liệu màn hình đọc sách, lấy thông tin tiến trình đọc cũ nếu có.
  Future<void> initialize(ReadingRouteArgs args) async {
    _bookId = args.bookId;
    _bookName = args.bookName;
    _isReadMode = args.isRead == 1;
    _chapters = args.chapters.where((c) => c.hasPdf).toList();
    if (_chapters.isEmpty) {
      _errorMessage = 'Khong co du lieu chuong de doc.';
      notifyListeners();
      return;
    }

    // Default values from arguments
    _chapterIndex = args.initialChapterIndex.clamp(0, _chapters.length - 1);
    _initialPage = 0;

    // Try fetching remote progress and book status (favourite)
    try {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        print('[ReadingProvider] Initializing data for bookId: $_bookId');
        
        // Fetch progress and book detail (for favourite status) in parallel
        final results = await Future.wait([
          _repository.getProgress(token: token, bookId: _bookId),
          BookDetailApiService(baseUrl: BookDetailApiService.defaultBaseUrl)
              .getBookDetail(token: token, id: _bookId),
        ]);

        final progress = results[0];
        if (progress != null) {
          final foundIndex = _chapters.indexWhere((c) => (progress as dynamic).chapterId == c.id);
          if (foundIndex != -1) {
            _chapterIndex = foundIndex;
            _initialPage = ((progress as dynamic).pageNumber - 1).clamp(0, 9999);
          }
        }

        final bookDetailResponse = results[1] as dynamic;
        if (bookDetailResponse != null && bookDetailResponse.data != null) {
          _isFavourite = bookDetailResponse.data.isFavourite ?? false;
        }
      }
    } catch (e) {
      print('[ReadingProvider] Error during initialization: $e');
    }

    _maxUnlockedChapterIndex = _isReadMode ? _chapters.length - 1 : _chapterIndex;
    _forceLockedPrompt = false;
    await _loadCurrentChapter();
  }

  /// Thêm hoặc xóa sách khỏi danh sách yêu thích.
  Future<void> toggleFavourite(BuildContext context) async {
    if (_isFavouriteLoading) return;
    _isFavouriteLoading = true;
    notifyListeners();

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) return;

      final apiService = BookDetailApiService(baseUrl: BookDetailApiService.defaultBaseUrl);
      
      if (_isFavourite) {
        await apiService.removeFavourite(token: token, bookId: _bookId);
        _isFavourite = false;
        if (context.mounted) _showSnackBar(context, 'Đã xoá khỏi danh sách yêu thích.');
      } else {
        await apiService.addFavourite(token: token, bookId: _bookId);
        _isFavourite = true;
        if (context.mounted) _showSnackBar(context, 'Đã thêm vào danh sách yêu thích!');
      }
    } catch (e) {
      if (context.mounted) _showSnackBar(context, 'Có lỗi xảy ra khi thực hiện bookmark.');
    } finally {
      _isFavouriteLoading = false;
      notifyListeners();
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Tải nội dung văn bản của chương hiện tại và phân trang hiển thị.
  Future<void> _loadCurrentChapter() async {
    final chapter = currentChapter;
    if (chapter == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _pageTexts = const [];
    _totalPages = 0;
    _currentPage = 0;
    notifyListeners();

    try {
      if (_bookName.trim().isEmpty) {
        throw const ReadingPdfException('Khong tim thay ten sach.');
      }
      final token = await _tokenStorage.getToken();
      final pages = await _repository.getChapterTextPages(
        bookName: _bookName,
        chapterNumber: chapter.chapterNumber,
        type: 'ebook',
        token: token,
      );
      if (pages.isEmpty) {
        _errorMessage = 'Khong the trich xuat noi dung PDF.';
      } else {
        _pageTexts = pages;
        _totalPages = pages.length;
        _currentPage = _initialPage.clamp(0, _totalPages - 1);
        _scrollProgress = _totalPages <= 1 ? 0.0 : _currentPage / (_totalPages - 1);
        _createScrollController();
        _pendingScrollPage = _currentPage;
      }
    } on ReadingPdfException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Khong the tai noi dung chuong.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _createScrollController() {
    _scrollController?.dispose();
    _scrollController = ScrollController();
  }

  int? consumePendingScrollPage() {
    final value = _pendingScrollPage;
    _pendingScrollPage = null;
    return value;
  }

  void updateScrollProgress(ScrollMetrics metrics) {
    if (_totalPages <= 0 || metrics.maxScrollExtent <= 0) {
      return;
    }
    final progress = (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0);
    _scrollProgress = progress;
    _currentPage = (_scrollProgress * (_totalPages - 1)).round().clamp(0, _totalPages - 1);
    notifyListeners();
  }

  /// Chuyển về trang đọc trước đó.
  Future<void> prevPage() async {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) {
      return;
    }
    final target = (controller.offset - controller.position.viewportDimension)
        .clamp(0.0, controller.position.maxScrollExtent);
    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  /// Chuyển sang trang đọc tiếp theo.
  Future<void> nextPage() async {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) {
      return;
    }
    final target = (controller.offset + controller.position.viewportDimension)
        .clamp(0.0, controller.position.maxScrollExtent);
    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  /// Chuyển về chương trước đó.
  Future<void> prevChapter() async {
    if (_chapterIndex <= 0) {
      return;
    }
    _chapterIndex -= 1;
    _initialPage = 0;
    await _loadCurrentChapter();
  }

  /// Chuyển sang chương tiếp theo.
  Future<void> nextChapter() async {
    if (_chapterIndex >= _chapters.length - 1) {
      return;
    }
    if (!_canAccessChapter(_chapterIndex + 1)) {
      showLockedPrompt();
      return;
    }
    _chapterIndex += 1;
    _initialPage = 0;
    await _loadCurrentChapter();
  }

  Future<void> goToChapter(int index) async {
    if (index < 0 || index >= _chapters.length || index == _chapterIndex) {
      return;
    }
    if (!_canAccessChapter(index)) {
      showLockedPrompt();
      return;
    }
    _chapterIndex = index;
    _initialPage = 0;
    _forceLockedPrompt = false;
    await _loadCurrentChapter();
  }

  void showLockedPrompt() {
    if (_isReadMode) {
      return;
    }
    if (_forceLockedPrompt) {
      return;
    }
    _forceLockedPrompt = true;
    notifyListeners();
  }

  void clearLockedPrompt() {
    if (!_forceLockedPrompt) {
      return;
    }
    _forceLockedPrompt = false;
    notifyListeners();
  }

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  /// Xử lý mua sách để mở khóa toàn bộ nội dung đọc.
  Future<void> purchaseBook(BuildContext context) async {
    if (_isPurchasing) return;
    
    _isPurchasing = true;
    notifyListeners();

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw const BookDetailApiException('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      print('[ReadingProvider] purchaseBook: Bắt đầu mua sách bookId=$_bookId');

      final apiService = BookDetailApiService(
        baseUrl: BookDetailApiService.defaultBaseUrl,
      );

      // Gọi API mua sách
      final response = await apiService.purchaseBook(token: token, bookId: _bookId);
      
      if (response.data != null) {
        print('[ReadingProvider] purchaseBook: Mua thành công! Bây giờ có thể đọc toàn bộ sách');
        _isReadMode = true;
        _forceLockedPrompt = false;
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mua sách thành công! Bây giờ bạn có thể đọc toàn bộ sách.')),
          );
        }
      } else {
        throw const BookDetailApiException('Không có dữ liệu trả về từ server.');
      }
    } on BookDetailApiException catch (e) {
      print('[ReadingProvider] purchaseBook: Lỗi - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      print('[ReadingProvider] purchaseBook: Lỗi không xác định - $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại.')),
        );
      }
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  bool canOpenChapter(int index) => _canAccessChapter(index);

  bool _canAccessChapter(int index) {
    if (_isReadMode) {
      return true;
    }
    return index <= _maxUnlockedChapterIndex;
  }

  /// Đồng bộ tiến trình đọc sách hiện tại lên server.
  Future<void> syncProgress() async {
    final chapter = currentChapter;
    if (chapter == null || _totalPages <= 0) {
      print('[ReadingProvider] Sync skipped: chapter or totalPages is null/zero');
      return;
    }

    final page = _currentPage + 1;
    final progressPercent = ((_currentPage + 1) / _totalPages.toDouble()) * 100.0;
    
    print('[ReadingProvider] Triggering syncProgress: bookId=$_bookId, chapterId=${chapter.id}, page=$page, progress=${progressPercent.toStringAsFixed(2)}%');

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        print('[ReadingProvider] Sync failed: No token found');
        return;
      }

      print('[ReadingProvider] Calling API: syncProgress');
      await _repository.syncProgress(
        token: token,
        bookId: _bookId,
        chapterId: chapter.id,
        pageNumber: page,
        offsetInPage: 0.0,
        progressPercent: progressPercent.clamp(0.0, 100.0),
      );
      print('[ReadingProvider] syncProgress call completed successfully');
    } catch (e) {
      print('[ReadingProvider] Error syncing reading progress: $e');
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }
}
