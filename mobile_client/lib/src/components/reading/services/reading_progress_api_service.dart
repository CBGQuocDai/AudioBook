import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';

/// Lớp cung cấp API để đồng bộ và lấy tiến trình đọc sách.
class ReadingProgressApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  ReadingProgressApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Gọi API đồng bộ (lưu) tiến trình đọc sách.
  Future<void> syncEbookProgress({
    required String token,
    required int bookId,
    required int chapterId,
    required int pageNumber,
    required double offsetInPage,
    required double progressPercent,
  }) async {
    final uri = Uri.parse('$baseUrl/books/progress/ebook');

    final response = await _guardedRequest(
      'POST $uri',
      () => _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bookId': bookId,
          'chapterId': chapterId,
          'pageNumber': pageNumber,
          'offsetInPage': offsetInPage,
          'progressPercent': progressPercent,
        }),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReadingProgressApiException(
        'Dong bo tien trinh doc that bai (${response.statusCode}).',
      );
    }
  }

  /// Gọi API lấy thông tin tiến trình đọc sách hiện tại.
  Future<Map<String, dynamic>?> getEbookProgress({
    required String token,
    required int bookId,
  }) async {
    final uri = Uri.parse('$baseUrl/books/progress/ebook/$bookId');

    final response = await _guardedRequest(
      'GET $uri',
      () => _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReadingProgressApiException(
        'Lay tien trinh doc that bai (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body);
    // Based on typical response structure { data: { ... } } or just { ... }
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>?;
    }
    return data as Map<String, dynamic>?;
  }

  Future<http.Response> _guardedRequest(
    String endpoint,
    Future<http.Response> Function() request,
  ) async {
    try {
      print('[ReadingProgressAPI][REQ] $endpoint');
      final response = await request();
      print('[ReadingProgressAPI][RES] $endpoint => ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('[ReadingProgressAPI][BODY] ${response.body}');
      }
      return response;
    } on SocketException {
      print('[ReadingProgressAPI][ERR] SocketException: Khong the ket noi may chu.');
      throw const ReadingProgressApiException('Khong the ket noi may chu.');
    } on http.ClientException catch (error) {
      print('[ReadingProgressAPI][ERR] ClientException: ${error.message}');
      throw ReadingProgressApiException('Loi ket noi: ${error.message}');
    } catch (e) {
      print('[ReadingProgressAPI][ERR] Unknown error: $e');
      rethrow;
    }
  }
}

class ReadingProgressApiException implements Exception {
  const ReadingProgressApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

