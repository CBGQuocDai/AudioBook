import 'package:audioplayers/audioplayers.dart';
import 'package:mobile_client/src/core/config/app_config.dart';
import 'package:http/http.dart' as http;

import '../model/audio_progress_model.dart';
import '../services/audio_book_source_service.dart';
import '../services/audio_progress_api_service.dart';

/// Lớp trừu tượng quản lý các thao tác dữ liệu liên quan đến sách nói (AudioBook).
abstract class AudioBookRepository {
  /// Lấy nguồn phát âm thanh từ một đường dẫn [url] cố định.
  Source getAudioSource(String url);

  /// Đồng bộ tiến trình nghe sách lên server.
  Future<void> syncProgress({
    required String token,
    required int bookId,
    required int chapterId,
    required int currentTime,
    required int duration,
    required double progressPercent,
    required double playbackSpeed,
  });

  /// Lấy tiến trình nghe sách từ server.
  Future<AudioProgressModel?> getProgress({
    required String token,
    required int bookId,
  });

  /// Lấy luồng dữ liệu (byte stream) của chương sách từ server dựa vào tên sách và số chương.
  Future<Source> getChapterAudioSource({
    required String bookName,
    required int chapterNumber,
    String? token,
  });
}

class AudioBookRepositoryImpl implements AudioBookRepository {
  AudioBookRepositoryImpl({
    AudioBookSourceService? sourceService,
    AudioProgressApiService? progressApiService,
  })  : _sourceService = sourceService ?? AudioBookSourceService(),
        _progressApiService = progressApiService ??
            AudioProgressApiService(baseUrl: AppConfig.apiBaseUrl);

  final AudioBookSourceService _sourceService;
  final AudioProgressApiService _progressApiService;

  @override
  Source getAudioSource(String url) {
    return _sourceService.createSource(url);
  }

  @override
  Future<void> syncProgress({
    required String token,
    required int bookId,
    required int chapterId,
    required int currentTime,
    required int duration,
    required double progressPercent,
    required double playbackSpeed,
  }) {
    return _progressApiService.syncAudioProgress(
      token: token,
      bookId: bookId,
      chapterId: chapterId,
      currentTime: currentTime,
      duration: duration,
      progressPercent: progressPercent,
      playbackSpeed: playbackSpeed,
    );
  }

  @override
  Future<AudioProgressModel?> getProgress({
    required String token,
    required int bookId,
  }) async {
    final data = await _progressApiService.getAudioProgress(
      token: token,
      bookId: bookId,
    );
    if (data == null) return null;
    return AudioProgressModel.fromJson(data);
  }

  @override
  Future<Source> getChapterAudioSource({
    required String bookName,
    required int chapterNumber,
    String? token,
  }) async {
    final trimmedName = bookName.trim();
    if (trimmedName.isEmpty || chapterNumber <= 0) {
      throw const AudioBookSourceException('Thong tin chuong audio khong hop le.');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/books/chapters/content').replace(
      queryParameters: {
        'bookName': trimmedName,
        'chapter': chapterNumber.toString(),
        'type': 'audio',
      },
    );

    final headers = token == null || token.isEmpty
        ? null
        : <String, String>{'Authorization': 'Bearer $token'};

    final response = await http.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('[AudioBookRepository] Chapter audio failed: $uri => ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('[AudioBookRepository] Body: ${response.body}');
      }
      throw AudioBookSourceException('Tai audio that bai (${response.statusCode}).');
    }

    return _sourceService.createBytesSource(
      response.bodyBytes,
      mimeType: response.headers['content-type'],
    );
  }
}
