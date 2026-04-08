import 'package:audioplayers/audioplayers.dart';

import '../services/audio_book_source_service.dart';

abstract class AudioBookRepository {
  Source getAudioSource(String url);
}

class AudioBookRepositoryImpl implements AudioBookRepository {
  AudioBookRepositoryImpl({
    AudioBookSourceService? sourceService,
  }) : _sourceService = sourceService ?? AudioBookSourceService();

  final AudioBookSourceService _sourceService;

  @override
  Source getAudioSource(String url) {
    return _sourceService.createSource(url);
  }
}

