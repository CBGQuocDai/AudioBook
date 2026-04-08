class EbookProgressResponse {
  final int? id;
  final int? pageNumber;
  final double? progressPercent;
  final String? lastReadAt;

  // Chapter info
  final int? chapterId;
  final String? chapterTitle;
  final int? chapterNumber;

  // Book info
  final int? bookId;
  final String? bookName;
  final String? bookAuthor;
  final String? bookCoverUrl;

  const EbookProgressResponse({
    this.id,
    this.pageNumber,
    this.progressPercent,
    this.lastReadAt,
    this.chapterId,
    this.chapterTitle,
    this.chapterNumber,
    this.bookId,
    this.bookName,
    this.bookAuthor,
    this.bookCoverUrl,
  });

  factory EbookProgressResponse.fromJson(Map<String, dynamic> json) {
    final coverFile = json['bookCoverFile'];
    String? coverUrl;
    if (coverFile is Map<String, dynamic>) {
      coverUrl = coverFile['filePath']?.toString();
    }

    final percent = json['progressPercent'];
    return EbookProgressResponse(
      id: json['id'] as int?,
      pageNumber: json['pageNumber'] as int?,
      progressPercent: percent is num ? percent.toDouble() : null,
      lastReadAt: json['lastReadAt']?.toString(),
      chapterId: json['chapterId'] as int?,
      chapterTitle: json['chapterTitle']?.toString(),
      chapterNumber: json['chapterNumber'] as int?,
      bookId: json['bookId'] as int?,
      bookName: json['bookName']?.toString(),
      bookAuthor: json['bookAuthor']?.toString(),
      bookCoverUrl: coverUrl,
    );
  }
}
