import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';

class ReadingProgressApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  ReadingProgressApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<void> syncEbookProgress({
    required String token,
    required int bookId,
    required int chapterId,
    required int chapterNumber,
  }) async {
    final uri = Uri.parse('$baseUrl/progress/ebook');

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
          'chapterNumber': chapterNumber,
        }),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReadingProgressApiException(
        'Dong bo tien trinh doc that bai (${response.statusCode}).',
      );
    }
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
      throw const ReadingProgressApiException('Khong the ket noi may chu.');
    } on http.ClientException catch (error) {
      throw ReadingProgressApiException('Loi ket noi: ${error.message}');
    }
  }
}

class ReadingProgressApiException implements Exception {
  const ReadingProgressApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

