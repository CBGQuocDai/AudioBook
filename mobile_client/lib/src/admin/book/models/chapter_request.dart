class EbookChapterRequest {
  final String title;
  final int chapterNumber;
  final int fileId;

  EbookChapterRequest({
    required this.title,
    required this.chapterNumber,
    required this.fileId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'chapterNumber': chapterNumber,
      'fileId': fileId,
    };
  }
}

class AudioChapterRequest {
  final String title;
  final int chapterNumber;
  final int durationSeconds;
  final int fileId;

  AudioChapterRequest({
    required this.title,
    required this.chapterNumber,
    required this.durationSeconds,
    required this.fileId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'chapterNumber': chapterNumber,
      'durationSeconds': durationSeconds,
      'fileId': fileId,
    };
  }
}
