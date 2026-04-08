class AudioProgressModel {
  const AudioProgressModel({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.currentTime,
    required this.duration,
    required this.progressPercent,
    required this.playbackSpeed,
    this.lastPlayedAt,
    this.chapterTitle,
    this.chapterNumber,
    this.chapterDurationSeconds,
    this.chapterFile,
    this.bookName,
    this.bookAuthor,
    this.bookCoverFile,
  });

  final int id;
  final int bookId;
  final int chapterId;
  final int currentTime;
  final int duration;
  final double progressPercent;
  final double playbackSpeed;
  final String? lastPlayedAt;
  final String? chapterTitle;
  final int? chapterNumber;
  final int? chapterDurationSeconds;
  final Map<String, dynamic>? chapterFile;
  final String? bookName;
  final String? bookAuthor;
  final Map<String, dynamic>? bookCoverFile;

  factory AudioProgressModel.fromJson(Map<String, dynamic> json) {
    return AudioProgressModel(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      chapterId: json['chapterId'] as int? ?? 0,
      currentTime: json['currentTime'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      lastPlayedAt: json['lastPlayedAt'] as String?,
      chapterTitle: json['chapterTitle'] as String?,
      chapterNumber: json['chapterNumber'] as int?,
      chapterDurationSeconds: json['chapterDurationSeconds'] as int?,
      chapterFile: json['chapterFile'] as Map<String, dynamic>?,
      bookName: json['bookName'] as String?,
      bookAuthor: json['bookAuthor'] as String?,
      bookCoverFile: json['bookCoverFile'] as Map<String, dynamic>?,
    );
  }
}

