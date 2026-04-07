import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/home/models/book_response.dart';
import '../services/book_detail_preview_api_service.dart';

class BookDetailPreviewProvider extends ChangeNotifier {
  final BookDetailPreviewApiService _apiService;
  final TokenStorageService _tokenStorageService;

  BookDetailPreviewProvider({
    BookDetailPreviewApiService? apiService,
    TokenStorageService? tokenStorageService,
  })  : _apiService = apiService ??
            BookDetailPreviewApiService(
              baseUrl: BookDetailPreviewApiService.defaultBaseUrl,
            ),
        _tokenStorageService = tokenStorageService ?? TokenStorageService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BookResponse? _book;
  BookResponse? get book => _book;

  int _currentTab = 0; // 0: Giới thiệu, 1: Chương
  int get currentTab => _currentTab;

  bool _isDescriptionExpanded = false;
  bool get isDescriptionExpanded => _isDescriptionExpanded;

  void changeTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
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
        throw const BookDetailPreviewApiException('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      final response = await _apiService.getBookDetails(
        token: token,
        id: id,
      );

      _book = response.data;
    } on BookDetailPreviewApiException catch (error) {
      _errorMessage = error.message;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không xác định.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
