import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';
import 'package:mobile_client/src/home/models/api_response_generic.dart';
import 'package:mobile_client/src/home/models/book_response.dart';
import 'package:mobile_client/src/components/library/models/client_response.dart';
import 'package:mobile_client/src/components/library/models/purchased_books_page_response.dart';

class LibraryApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  LibraryApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<ApiResponseGeneric<ClientResponse>> getClientProfile({
    required String token,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/client/me',
      () => _client.get(
        Uri.parse('$baseUrl/client/me'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return ApiResponseGeneric<ClientResponse>.fromJson(
      body,
      (json) => ClientResponse.fromJson(json),
    );
  }

  Future<ApiResponseGeneric<List<BookResponse>>> getFavouriteBooks({
    required String token,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/books/favourite',
      () => _client.get(
        Uri.parse('$baseUrl/books/favourite'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    List<BookResponse> items = [];
    if (body['data'] is List) {
      items = (body['data'] as List)
          .map((item) => BookResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ApiResponseGeneric<List<BookResponse>>(
      code: _extractCode(body),
      data: items,
      message: body['message']?.toString() ?? '',
    );
  }

  Future<ApiResponseGeneric<PurchasedBooksPageResponse>> getPurchasedBooks({
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/purchased?page=$page&size=$size',
      () => _client.get(
        Uri.parse('$baseUrl/purchased?page=$page&size=$size'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return ApiResponseGeneric<PurchasedBooksPageResponse>.fromJson(
      body,
      (json) => PurchasedBooksPageResponse.fromJson(json),
    );
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final dynamic decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw LibraryApiException('Response format không hợp lệ.');
  }

  void _ensureSuccess(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300) {
      throw LibraryApiException(_extractErrorMessage(body, statusCode));
    }

    final code = _extractCode(body);

    if (code != 1000) {
      final msg = _extractErrorMessage(body, statusCode);
      throw LibraryApiException(msg);
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
      throw LibraryApiException(
        'Không thể kết nối máy chủ. Kiểm tra API đang chạy và base URL.',
      );
    } on http.ClientException catch (error) {
      throw LibraryApiException('Lỗi kết nối: ${error.message}');
    }
  }
}

class LibraryApiException implements Exception {
  const LibraryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
