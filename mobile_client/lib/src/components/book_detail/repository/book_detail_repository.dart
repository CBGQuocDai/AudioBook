import 'package:mobile_client/src/components/book_detail/model/book_detail_model.dart';
import 'package:mobile_client/src/components/book_detail/services/book_detail_api_service.dart';

/// Lớp trừu tượng định nghĩa các phương thức giao tiếp với dữ liệu chi tiết sách.
abstract class BookDetailRepository {
  /// Lấy thông tin chi tiết của một cuốn sách.
  /// [token]: Token xác thực của người dùng.
  /// [id]: ID của cuốn sách cần lấy thông tin.
  Future<BookDetailModel?> getBookDetail({
    required String token,
    required int id,
  });
}

/// Lớp triển khai thực tế của [BookDetailRepository], gọi API thông qua [BookDetailApiService].
class BookDetailRepositoryImpl implements BookDetailRepository {
  BookDetailRepositoryImpl({
    BookDetailApiService? apiService,
  }) : _apiService = apiService ??
            BookDetailApiService(
              baseUrl: BookDetailApiService.defaultBaseUrl,
            );

  final BookDetailApiService _apiService;

  @override
  /// Lấy thông tin chi tiết sách từ API.
  Future<BookDetailModel?> getBookDetail({
    required String token,
    required int id,
  }) async {
    final response = await _apiService.getBookDetail(token: token, id: id);
    return response.data;
  }
}

