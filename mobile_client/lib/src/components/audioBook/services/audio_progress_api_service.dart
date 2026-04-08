import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';

class AudioProgressApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  AudioProgressApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<void> syncAudioProgress({
    required String token,
    required int bookId,
    required int chapterId,
    required int currentTime,
    required int duration,
    required double progressPercent,
    required double playbackSpeed,
  }) async {
    final uri = Uri.parse('$baseUrl/books/progress/audio');

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
          'currentTime': currentTime,
          'duration': duration,
          'progressPercent': progressPercent,
          'playbackSpeed': playbackSpeed,
        }),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AudioProgressApiException(
        'Dong bo tien trinh nghe that bai (${response.statusCode}).',
      );
    }
  }

  Future<Map<String, dynamic>?> getAudioProgress({
    required String token,
    required int bookId,
  }) async {
    final uri = Uri.parse('$baseUrl/books/progress/audio/$bookId');

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
      throw AudioProgressApiException(
        'Lay tien trinh nghe that bai (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body);
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
      print('[AudioProgressAPI][REQ] $endpoint');
      final response = await request();
      print('[AudioProgressAPI][RES] $endpoint => ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('[AudioProgressAPI][BODY] ${response.body}');
      }
      return response;
    } on SocketException {
      print('[AudioProgressAPI][ERR] SocketException: Khong the ket noi may chu.');
      throw const AudioProgressApiException('Khong the ket noi may chu.');
    } on http.ClientException catch (error) {
      print('[AudioProgressAPI][ERR] ClientException: ${error.message}');
      throw AudioProgressApiException('Loi ket noi: ${error.message}');
    } catch (e) {
      print('[AudioProgressAPI][ERR] Unknown error: $e');
      rethrow;
    }
  }
}

class AudioProgressApiException implements Exception {
  const AudioProgressApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
