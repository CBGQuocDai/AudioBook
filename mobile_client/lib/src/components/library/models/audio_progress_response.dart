class AudioProgressResponse {
  final int? id;
  final int? currentTime;
  final int? duration;
  final double? progressPercent;
  final double? playbackSpeed;
  final String? lastPlayedAt;

  // Chapter info
  final int? chapterId;
  final String? chapterTitle;
  final int? chapterNumber;
  final int? chapterDurationSeconds;
  final String? chapterFilePath;
  final String? chapterFileName;

  // Book info
  final int? bookId;
  final String? bookName;
  final String? bookAuthor;
  final String? bookCoverUrl;

  const AudioProgressResponse({
    this.id,
    this.currentTime,
    this.duration,
    this.progressPercent,
    this.playbackSpeed,
    this.lastPlayedAt,
    this.chapterId,
    this.chapterTitle,
    this.chapterNumber,
    this.chapterDurationSeconds,
    this.chapterFilePath,
    this.chapterFileName,
    this.bookId,
    this.bookName,
    this.bookAuthor,
    this.bookCoverUrl,
  });

  factory AudioProgressResponse.fromJson(Map<String, dynamic> json) {
    final coverFile = json['bookCoverFile'];
    String? coverUrl;
    if (coverFile is Map<String, dynamic>) {
      coverUrl = coverFile['filePath']?.toString();
    }

    final chapterFile = json['chapterFile'];
    String? chapterFilePath;
    String? chapterFileName;
    if (chapterFile is Map<String, dynamic>) {
      chapterFilePath = chapterFile['filePath']?.toString();
      chapterFileName = chapterFile['fileName']?.toString();
    }

    final percent = json['progressPercent'];
    final speed = json['playbackSpeed'];

    return AudioProgressResponse(
      id: json['id'] as int?,
      currentTime: json['currentTime'] as int?,
      duration: json['duration'] as int?,
      progressPercent: percent is num ? percent.toDouble() : null,
      playbackSpeed: speed is num ? speed.toDouble() : null,
      lastPlayedAt: json['lastPlayedAt']?.toString(),
      chapterId: json['chapterId'] as int?,
      chapterTitle: json['chapterTitle']?.toString(),
      chapterNumber: json['chapterNumber'] as int?,
      chapterDurationSeconds: json['chapterDurationSeconds'] as int?,
      chapterFilePath: chapterFilePath,
      chapterFileName: chapterFileName,
      bookId: json['bookId'] as int?,
      bookName: json['bookName']?.toString(),
      bookAuthor: json['bookAuthor']?.toString(),
      bookCoverUrl: coverUrl,
    );
  }
}
