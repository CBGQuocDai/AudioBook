import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/components/book_detail/services/book_detail_api_service.dart';
import 'package:provider/provider.dart';

import '../model/reading_chapter_model.dart';
import '../model/reading_route_args.dart';
import '../repository/reading_repository.dart';
import '../services/reading_pdf_service.dart';

class ReadingProvider extends ChangeNotifier {
  ReadingProvider({
    ReadingRepository? repository,
  }) : _repository = repository ?? ReadingRepositoryImpl();

  final ReadingRepository _repository;
  final TokenStorageService _tokenStorage = TokenStorageService();

  int _bookId = 0;
  int get bookId => _bookId;
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

  String? _localPdfPath;
  String? get localPdfPath => _localPdfPath;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  PDFViewController? _pdfController;
  int _initialPage = 0;
  int get initialPage => _initialPage;

  bool _isFavourite = false;
  bool get isFavourite => _isFavourite;

  bool _isFavouriteLoading = false;
  bool get isFavouriteLoading => _isFavouriteLoading;

  double get progress {
    if (_totalPages <= 0) {
      return 0;
    }
    return (_currentPage + 1) / _totalPages;
  }

  Future<void> initialize(ReadingRouteArgs args) async {
    _bookId = args.bookId;
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

  Future<void> _loadCurrentChapter() async {
    final chapter = currentChapter;
    if (chapter == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _totalPages = 0;
    _currentPage = 0;
    _localPdfPath = null;
    notifyListeners();

    try {
      _localPdfPath = await _repository.getLocalPdfPath(
        pdfUrl: chapter.filePath,
        fileName: chapter.fileName,
      );
    } on ReadingPdfException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Khong the tai noi dung chuong.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onViewCreated(PDFViewController controller) {
    _pdfController = controller;
  }

  void onRender(int? pages) {
    _totalPages = pages ?? 0;
    notifyListeners();
  }

  void onPageChanged(int? page, int? pages) {
    _currentPage = page ?? 0;
    _totalPages = pages ?? _totalPages;
    notifyListeners();
  }

  Future<void> prevPage() async {
    if (_pdfController == null || _currentPage <= 0) {
      return;
    }
    await _pdfController!.setPage(_currentPage - 1);
  }

  Future<void> nextPage() async {
    if (_pdfController == null || _totalPages <= 0 || _currentPage >= _totalPages - 1) {
      return;
    }
    await _pdfController!.setPage(_currentPage + 1);
  }

  Future<void> prevChapter() async {
    if (_chapterIndex <= 0) {
      return;
    }
    _chapterIndex -= 1;
    _initialPage = 0;
    await _loadCurrentChapter();
  }

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

  bool canOpenChapter(int index) => _canAccessChapter(index);

  bool _canAccessChapter(int index) {
    if (_isReadMode) {
      return true;
    }
    return index <= _maxUnlockedChapterIndex;
  }

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
}


