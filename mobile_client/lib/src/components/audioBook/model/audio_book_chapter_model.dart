class AudioBookChapterModel {
  const AudioBookChapterModel({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.filePath,
    required this.fileName,
    required this.durationSeconds,
  });

  final int id;
  final String title;
  final int chapterNumber;
  final String filePath;
  final String fileName;
  final int durationSeconds;

  bool get hasAudio => filePath.trim().isNotEmpty;
}

