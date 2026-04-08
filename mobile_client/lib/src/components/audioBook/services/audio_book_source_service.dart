import 'package:audioplayers/audioplayers.dart';

class AudioBookSourceService {
  Source createSource(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw const AudioBookSourceException('File audio khong hop le.');
    }
    return UrlSource(trimmed);
  }
}

class AudioBookSourceException implements Exception {
  const AudioBookSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}

