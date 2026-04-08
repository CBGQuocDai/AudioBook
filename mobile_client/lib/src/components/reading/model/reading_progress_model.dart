class ReadingProgressModel {
  const ReadingProgressModel({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.pageNumber,
    required this.offsetInPage,
    required this.progressPercent,
    this.lastReadAt,
    this.chapterTitle,
    this.chapterNumber,
    this.bookName,
    this.bookAuthor,
    this.chapterFile,
    this.bookCoverFile,
  });

  final int id;
  final int bookId;
  final int chapterId;
  final int pageNumber;
  final double offsetInPage;
  final double progressPercent;
  final String? lastReadAt;
  final String? chapterTitle;
  final int? chapterNumber;
  final String? bookName;
  final String? bookAuthor;
  final Map<String, dynamic>? chapterFile;
  final Map<String, dynamic>? bookCoverFile;

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      chapterId: json['chapterId'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 0,
      offsetInPage: (json['offsetInPage'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      lastReadAt: json['lastReadAt'] as String?,
      chapterTitle: json['chapterTitle'] as String?,
      chapterNumber: json['chapterNumber'] as int?,
      bookName: json['bookName'] as String?,
      bookAuthor: json['bookAuthor'] as String?,
      chapterFile: json['chapterFile'] as Map<String, dynamic>?,
      bookCoverFile: json['bookCoverFile'] as Map<String, dynamic>?,
    );
  }
}

