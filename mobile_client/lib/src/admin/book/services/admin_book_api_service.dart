import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../user/models/api_response.dart';
import '../../user/models/page_response.dart';
import '../models/admin_book_response.dart';
import '../models/admin_book_search_request.dart';
import '../models/book_category_response.dart';
import '../models/book_request.dart';

class AdminBookApiService {
  final String baseUrl;
  final Future<String?> Function() getAccessToken;

  AdminBookApiService({
    required this.baseUrl,
    required this.getAccessToken,
  });

  Future<Map<String, String>> _headers() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  Exception _buildException(http.Response response) {
    try {
      final body = _decodeResponse(response);
      if (body is Map<String, dynamic>) {
        return Exception(body['message'] ?? 'Request failed');
      }
      return Exception('Request failed');
    } catch (_) {
      return Exception('Request failed: ${response.statusCode}');
    }
  }

  Future<PageResponse<AdminBookResponse>> searchBooks(AdminBookSearchRequest request) async {
    final uri = Uri.parse('$baseUrl/admin/books/search').replace(
      queryParameters: request.toQueryParameters(),
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<PageResponse<AdminBookResponse>>.fromJson(
        body,
        (data) => PageResponse<AdminBookResponse>.fromJson(
          data as Map<String, dynamic>,
          AdminBookResponse.fromJson,
        ),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<AdminBookResponse> getBookById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/books/$id'),
      headers: await _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<AdminBookResponse>.fromJson(
        body,
        (data) => AdminBookResponse.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<AdminBookResponse> createBook(CreateBookRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/books'),
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<AdminBookResponse>.fromJson(
        body,
        (data) => AdminBookResponse.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<AdminBookResponse> updateBook(int id, UpdateBookRequest request) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/books/$id'),
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<AdminBookResponse>.fromJson(
        body,
        (data) => AdminBookResponse.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<void> deleteBook(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/books/$id'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }
  }

  Future<List<BookCategoryResponse>> searchCategories({
    String keyword = '',
    int page = 0,
    int size = 100,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/books/categories/search').replace(
      queryParameters: {
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<PageResponse<BookCategoryResponse>>.fromJson(
        body,
        (data) => PageResponse<BookCategoryResponse>.fromJson(
          data as Map<String, dynamic>,
          BookCategoryResponse.fromJson,
        ),
      );
      return apiResponse.data.content;
    }

    throw _buildException(response);
  }
}
