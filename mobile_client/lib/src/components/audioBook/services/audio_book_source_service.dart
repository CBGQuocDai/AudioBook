import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class AudioBookSourceService {
  Source createSource(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw const AudioBookSourceException('File audio khong hop le.');
    }
    return UrlSource(trimmed);
  }

  Source createBytesSource(Uint8List bytes, {String? mimeType}) {
    if (bytes.isEmpty) {
      throw const AudioBookSourceException('Noi dung audio rong.');
    }
    return BytesSource(bytes, mimeType: mimeType);
  }
}

class AudioBookSourceException implements Exception {
  const AudioBookSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}
