import 'package:flutter/material.dart';
import 'package:mobile_client/src/components/audioBook/model/audio_book_chapter_model.dart';
import 'package:mobile_client/src/components/audioBook/model/audio_book_route_args.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/components/book_detail/model/book_detail_model.dart';
import 'package:mobile_client/src/components/book_detail/repository/book_detail_repository.dart';
import 'package:mobile_client/src/components/book_detail/services/book_detail_api_service.dart';
import 'package:mobile_client/src/components/reading/model/reading_chapter_model.dart';
import 'package:mobile_client/src/components/reading/model/reading_route_args.dart';
import 'package:mobile_client/src/payment/screens/buy_credit_screen.dart';
import 'package:mobile_client/src/util/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class BookDetailProvider extends ChangeNotifier {
  BookDetailProvider({
    BookDetailRepository? repository,
    TokenStorageService? tokenStorageService,
    bool forceReadMode = false,
  })  : _repository = repository ?? BookDetailRepositoryImpl(),
        _tokenStorageService = tokenStorageService ?? TokenStorageService(),
        _forceReadMode = forceReadMode;

  final BookDetailRepository _repository;
  final TokenStorageService _tokenStorageService;
  final bool _forceReadMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BookDetailModel? _book;
  BookDetailModel? get book => _book;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  bool _isDescriptionExpanded = false;
  bool get isDescriptionExpanded => _isDescriptionExpanded;

  bool _isFavourite = false;
  bool get isFavourite => _isFavourite;

  bool _isFavouriteLoading = false;
  bool get isFavouriteLoading => _isFavouriteLoading;

  void changeTab(int index) {
    if (_currentTab == index) {
      return;
    }
    _currentTab = index;
    notifyListeners();
  }

  void toggleDescription() {
    _isDescriptionExpanded = !_isDescriptionExpanded;
    notifyListeners();
  }

  Future<void> fetchBookDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const BookDetailApiException('Khong tim thay token. Vui long dang nhap lai.');
      }

      _book = await _repository.getBookDetail(token: token, id: id);
    } on BookDetailApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Da xay ra loi khong xac dinh.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavourite(BuildContext context, int bookId) async {
    if (_isFavouriteLoading) return;
    _isFavouriteLoading = true;
    notifyListeners();

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const BookDetailApiException('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      final apiService = BookDetailApiService(
        baseUrl: BookDetailApiService.defaultBaseUrl,
      );

      if (_isFavourite) {
        await apiService.removeFavourite(token: token, bookId: bookId);
        _isFavourite = false;
        if (context.mounted) {
          _showMessage(context, 'Đã xoá khỏi danh sách yêu thích.');
        }
      } else {
        await apiService.addFavourite(token: token, bookId: bookId);
        _isFavourite = true;
        if (context.mounted) {
          _showMessage(context, 'Đã thêm vào danh sách yêu thích!');
        }
      }
    } on BookDetailApiException catch (e) {
      if (context.mounted) {
        _showMessage(context, e.message);
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Có lỗi xảy ra. Vui lòng thử lại.');
      }
    } finally {
      _isFavouriteLoading = false;
      notifyListeners();
    }
  }

  bool get isReadMode => _forceReadMode || (_book?.canRead ?? false);

  String get aboutText {
    final text = _book?.description ?? '';
    if (text.trim().isNotEmpty) {
      return text;
    }
    return 'No description available.';
  }

  List<EbookChapterModel> get ebookChapters => _book?.ebookChapters ?? const [];

  List<AudioChapterModel> get audioChapters => _book?.audioChapters ?? const [];

  List<String> get categories =>
      (_book?.categories ?? const <BookCategoryModel>[])
          .map((e) => e.name)
          .where((e) => e.trim().isNotEmpty)
          .toList();

  String? get coverUrl => _book?.coverFile?.filePath;

  List<String> get descriptionImageUrls =>
      (_book?.descriptionImages ?? const <BookFileModel>[])
          .map((e) => e.filePath)
          .where((e) => e.trim().isNotEmpty)
          .toList();

  Future<void> openEbookChapter(BuildContext context, int index) async {
    if (!isReadMode) {
      _showMessage(context, 'Bạn chỉ có thể đọc thử chương đầu tiên. Vui lòng mua để mở khoá.');
      return;
    }
    await _openReadingByIndex(context, index);
  }

  Future<void> openAudioChapter(BuildContext context, int index) async {
    if (audioChapters.isEmpty) {
      _showMessage(context, 'Chưa có chương audio.');
      return;
    }

    if (!isReadMode) {
      _showMessage(context, 'Bạn chỉ có thể nghe sau khi đã mua sách. Vui lòng mua để mở khóa.');
      return;
    }

    await _openAudioByIndex(context, index);
  }

  Future<void> openFirstEbook(BuildContext context) async {
    await _openUrl(
      context,
      ebookChapters.isNotEmpty ? ebookChapters.first.file?.filePath : null,
    );
  }

  Future<void> openFirstReading(BuildContext context) async {
    final chapterOneOriginalIndex = ebookChapters.indexWhere((c) => c.chapterNumber == 1);
    final initialIndex = chapterOneOriginalIndex >= 0 ? chapterOneOriginalIndex : 0;
    
    print('[BookDetailProvider] openFirstReading: defaulting to chapterNumber 1 (index $initialIndex)');
    await _openReadingByIndex(context, initialIndex);
  }

  Future<void> _openReadingByIndex(BuildContext context, int originalIndex) async {
    if (ebookChapters.isEmpty) {
      _showMessage(context, 'Chưa có chương để đọc.');
      return;
    }

    final chapters = <ReadingChapterModel>[];
    var selectedReadingIndex = -1;

    for (var i = 0; i < ebookChapters.length; i++) {
      final chapter = ebookChapters[i];
      final filePath = chapter.file?.filePath ?? '';
      if (filePath.trim().isEmpty) {
        continue;
      }

      if (i == originalIndex) {
        selectedReadingIndex = chapters.length;
      }

      chapters.add(
        ReadingChapterModel(
          id: chapter.id,
          title: chapter.title,
          chapterNumber: chapter.chapterNumber,
          filePath: filePath,
          fileName: chapter.file?.fileName ?? 'chapter_${chapter.chapterNumber}.pdf',
        ),
      );
    }

    if (chapters.isEmpty) {
      _showMessage(context, 'Không có file PDF hợp lệ.');
      return;
    }

    final initialIndex = selectedReadingIndex >= 0 ? selectedReadingIndex : 0;

    await Navigator.pushNamed(
      context,
      AppRoutes.reading,
      arguments: ReadingRouteArgs(
        bookId: _book?.id ?? 0,
        chapters: chapters,
        initialChapterIndex: initialIndex,
        isRead: isReadMode ? 1 : 0,
      ),
    );
  }

  Future<void> openFirstAudio(BuildContext context) async {
    if (audioChapters.isEmpty) {
      _showMessage(context, 'Chưa có chương audio.');
      return;
    }

    // Kiểm tra nếu chưa mua sách, hiển thị popup mua
    if (!isReadMode) {
      _showBuyPopup(context);
      return;
    }

    final chapterOneIndex = audioChapters.indexWhere((c) => c.chapterNumber == 1);
    final initialIndex = chapterOneIndex >= 0 ? chapterOneIndex : 0;
    
    print('[BookDetailProvider] openFirstAudio: defaulting to chapterNumber 1 (index $initialIndex)');
    await _openAudioByIndex(context, initialIndex);
  }

  Future<void> _openAudioByIndex(BuildContext context, int originalIndex) async {
    if (audioChapters.isEmpty) {
      _showMessage(context, 'Chưa có chương audio.');
      return;
    }

    final chapters = <AudioBookChapterModel>[];
    var selectedAudioIndex = -1;

    for (var i = 0; i < audioChapters.length; i++) {
      final chapter = audioChapters[i];
      final filePath = chapter.file?.filePath ?? '';
      if (filePath.trim().isEmpty) {
        continue;
      }

      if (i == originalIndex) {
        selectedAudioIndex = chapters.length;
      }

      chapters.add(
        AudioBookChapterModel(
          id: chapter.id,
          title: chapter.title,
          chapterNumber: chapter.chapterNumber,
          filePath: filePath,
          fileName: chapter.file?.fileName ?? 'audio_${chapter.chapterNumber}.mp3',
          durationSeconds: chapter.durationSeconds,
        ),
      );
    }

    if (chapters.isEmpty) {
      _showMessage(context, 'Không có file audio hợp lệ.');
      return;
    }

    final initialIndex = selectedAudioIndex >= 0 ? selectedAudioIndex : 0;

    await Navigator.pushNamed(
      context,
      AppRoutes.audioBook,
      arguments: AudioBookRouteArgs(
        bookId: _book?.id ?? 0,
        bookTitle: _book?.name ?? 'Audio Book',
        author: _book?.author ?? '',
        coverUrl: _book?.coverFile?.filePath,
        chapters: chapters,
        initialChapterIndex: initialIndex,
        isRead: isReadMode ? 1 : 0,
      ),
    );
  }

  Future<void> openImage(BuildContext context, String url) async {
    await _openUrl(context, url);
  }

  Future<void> _openUrl(BuildContext context, String? rawUrl) async {
    final url = rawUrl?.trim() ?? '';
    if (url.isEmpty) {
      _showMessage(context, 'Không có đường dẫn hợp lệ.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage(context, 'URL không hợp lệ: $url');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) {
      return;
    }
    if (!launched) {
      _showMessage(context, 'Không thể mở URL.');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showBuyPopup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BuyCreditScreen()),
    );
  }

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  Future<void> purchaseBook(BuildContext context) async {
    if (_isPurchasing || _book == null) return;
    
    _isPurchasing = true;
    notifyListeners();

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const BookDetailApiException('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      print('[BookDetailProvider] purchaseBook: Bắt đầu mua sách bookId=${_book!.id}');

      final apiService = BookDetailApiService(
        baseUrl: BookDetailApiService.defaultBaseUrl,
      );

      // Gọi API mua sách
      final response = await apiService.purchaseBook(token: token, bookId: _book!.id);
      
      if (response.data != null) {
        print('[BookDetailProvider] purchaseBook: Mua thành công! Cập nhật dữ liệu...');
        _book = response.data;
        
        if (context.mounted) {
          _showMessage(context, 'Mua sách thành công! Bây giờ bạn có thể đọc/nghe toàn bộ sách.');
        }
        
        // Reload lại book details để đảm bảo dữ liệu mới nhất
        await fetchBookDetails(_book!.id);
      } else {
        throw const BookDetailApiException('Không có dữ liệu trả về từ server.');
      }
    } on BookDetailApiException catch (e) {
      print('[BookDetailProvider] purchaseBook: Lỗi - ${e.message}');
      if (context.mounted) {
        _showMessage(context, e.message);
      }
    } catch (e) {
      print('[BookDetailProvider] purchaseBook: Lỗi không xác định - $e');
      if (context.mounted) {
        _showMessage(context, 'Có lỗi xảy ra. Vui lòng thử lại.');
      }
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }
}
