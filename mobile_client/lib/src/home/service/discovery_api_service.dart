import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';
import 'package:mobile_client/src/home/models/api_response_generic.dart';
import 'package:mobile_client/src/home/models/books_page_response.dart';

class DiscoveryApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  DiscoveryApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Search books by keyword
  Future<ApiResponseGeneric<BooksPageResponse>> searchBooks({
    required String keyword,
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/books/search?keyword=$keyword&page=$page&size=$size',
      () => _client.get(
        Uri.parse(
            '$baseUrl/books/search?keyword=$keyword&page=$page&size=$size'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final apiResponse = ApiResponseGeneric<BooksPageResponse>.fromJson(
      body,
      (json) => BooksPageResponse.fromJson(json),
    );

    return apiResponse;
  }

  /// Get trending books
  Future<ApiResponseGeneric<BooksPageResponse>> getTrendingBooks({
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/books/trending?page=$page&size=$size',
      () => _client.get(
        Uri.parse('$baseUrl/books/trending?page=$page&size=$size'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final apiResponse = ApiResponseGeneric<BooksPageResponse>.fromJson(
      body,
      (json) => BooksPageResponse.fromJson(json),
    );

    return apiResponse;
  }

  /// Get new arrivals
  Future<ApiResponseGeneric<BooksPageResponse>> getNewArrivals({
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/books/new?page=$page&size=$size',
      () => _client.get(
        Uri.parse('$baseUrl/books/new?page=$page&size=$size'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final apiResponse = ApiResponseGeneric<BooksPageResponse>.fromJson(
      body,
      (json) => BooksPageResponse.fromJson(json),
    );

    return apiResponse;
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final dynamic decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw DiscoveryApiException('Response format không hợp lệ.');
  }

  void _ensureSuccess(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300) {
      throw DiscoveryApiException(_extractErrorMessage(body, statusCode));
    }

    final code = _extractCode(body);

    if (code != 1000) {
      final msg = _extractErrorMessage(body, statusCode);
      throw DiscoveryApiException(msg);
    }
  }

  int _extractCode(Map<String, dynamic> body) {
    final dynamic value = body['code'];
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 1000;
    }
    return 1000;
  }

  String _extractErrorMessage(Map<String, dynamic> body, int statusCode) {
    return body['message']?.toString() ??
        body['error']?.toString() ??
        'Request thất bại ($statusCode).';
  }

  Future<http.Response> _guardedRequest(
    String endpoint,
    Future<http.Response> Function() request,
  ) async {
    try {
      log('[API][REQ] $endpoint');
      final response = await request();
      log('[API][RES] $endpoint => ${response.statusCode}');
      return response;
    } on SocketException {
      throw DiscoveryApiException(
        'Không thể kết nối máy chủ. Kiểm tra API đang chạy và base URL.',
      );
    } on http.ClientException catch (error) {
      throw DiscoveryApiException('Lỗi kết nối: ${error.message}');
    }
  }
}

class DiscoveryApiException implements Exception {
  const DiscoveryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
