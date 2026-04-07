class ReadingChapterModel {
  const ReadingChapterModel({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.filePath,
    required this.fileName,
  });

  final int id;
  final String title;
  final int chapterNumber;
  final String filePath;
  final String fileName;

  bool get hasPdf => filePath.trim().isNotEmpty;
}

