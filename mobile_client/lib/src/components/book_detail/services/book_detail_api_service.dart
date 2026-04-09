import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/components/book_detail/model/book_detail_model.dart';
import 'package:mobile_client/src/core/config/app_config.dart';
import 'package:mobile_client/src/home/models/api_response_generic.dart';

class BookDetailApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  BookDetailApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<ApiResponseGeneric<BookDetailModel>> getBookDetail({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/books/$id');
    final response = await _guardedRequest(
      'GET $uri',
      () => _client.get(
        uri,
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return ApiResponseGeneric<BookDetailModel>.fromJson(
      body,
      (json) => BookDetailModel.fromJson(json),
    );
  }

  Future<void> addFavourite({
    required String token,
    required int bookId,
  }) async {
    final uri = Uri.parse('$baseUrl/books/favourite/$bookId');
    final response = await _guardedRequest(
      'POST $uri',
      () => _client.post(
        uri,
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );
    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);
  }

  Future<void> removeFavourite({
    required String token,
    required int bookId,
  }) async {
    final uri = Uri.parse('$baseUrl/books/favourite/$bookId');
    final response = await _guardedRequest(
      'DELETE $uri',
      () => _client.delete(
        uri,
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );
    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);
  }

  Future<ApiResponseGeneric<BookDetailModel>> purchaseBook({
    required String token,
    required int bookId,
  }) async {
    final uri = Uri.parse('$baseUrl/purchased/$bookId');
    print('[API][CALL] POST $uri - Mua sách');
    
    final response = await _guardedRequest(
      'POST $uri',
      () => _client.post(
        uri,
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return ApiResponseGeneric<BookDetailModel>.fromJson(
      body,
      (json) => BookDetailModel.fromJson(json),
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
    throw const BookDetailApiException('Response format khong hop le.');
  }

  void _ensureSuccess(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300) {
      throw BookDetailApiException(_extractErrorMessage(body, statusCode));
    }

    final code = body['code'];
    final parsedCode = code is int ? code : int.tryParse('$code') ?? -1;
    if (parsedCode != 1000) {
      throw BookDetailApiException(_extractErrorMessage(body, statusCode));
    }
  }

  String _extractErrorMessage(Map<String, dynamic> body, int statusCode) {
    return body['message']?.toString() ??
        body['error']?.toString() ??
        'Request that bai ($statusCode).';
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
      throw const BookDetailApiException(
        'Khong the ket noi may chu. Kiem tra API dang chay va base URL.',
      );
    } on http.ClientException catch (error) {
      throw BookDetailApiException('Loi ket noi: ${error.message}');
    }
  }
}

class BookDetailApiException implements Exception {
  const BookDetailApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

