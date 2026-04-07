import 'package:mobile_client/src/components/book_detail/model/book_detail_model.dart';
import 'package:mobile_client/src/components/book_detail/services/book_detail_api_service.dart';

abstract class BookDetailRepository {
  Future<BookDetailModel?> getBookDetail({
    required String token,
    required int id,
  });
}

class BookDetailRepositoryImpl implements BookDetailRepository {
  BookDetailRepositoryImpl({
    BookDetailApiService? apiService,
  }) : _apiService = apiService ??
            BookDetailApiService(
              baseUrl: BookDetailApiService.defaultBaseUrl,
            );

  final BookDetailApiService _apiService;

  @override
  Future<BookDetailModel?> getBookDetail({
    required String token,
    required int id,
  }) async {
    final response = await _apiService.getBookDetail(token: token, id: id);
    return response.data;
  }
}

