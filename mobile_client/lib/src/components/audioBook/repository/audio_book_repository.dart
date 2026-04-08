import 'package:audioplayers/audioplayers.dart';
import 'package:mobile_client/src/core/config/app_config.dart';

import '../model/audio_progress_model.dart';
import '../services/audio_book_source_service.dart';
import '../services/audio_progress_api_service.dart';

abstract class AudioBookRepository {
  Source getAudioSource(String url);

  Future<void> syncProgress({
    required String token,
    required int bookId,
    required int chapterId,
    required int currentTime,
    required int duration,
    required double progressPercent,
    required double playbackSpeed,
  });

  Future<AudioProgressModel?> getProgress({
    required String token,
    required int bookId,
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
}
