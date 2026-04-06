import '../../user/models/file_dto.dart';

class BookCategoryItemResponse {
  final int id;
  final String name;

  BookCategoryItemResponse({
    required this.id,
    required this.name,
  });

  factory BookCategoryItemResponse.fromJson(Map<String, dynamic> json) {
    return BookCategoryItemResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class EbookChapterResponse {
  final int id;
  final String title;
  final int chapterNumber;
  final FileDto? file;

  EbookChapterResponse({
    required this.id,
    required this.title,
    required this.chapterNumber,
    this.file,
  });

  factory EbookChapterResponse.fromJson(Map<String, dynamic> json) {
    return EbookChapterResponse(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      chapterNumber: json['chapterNumber'] ?? 0,
      file: json['file'] is Map<String, dynamic>
          ? FileDto.fromJson(json['file'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AudioChapterResponse {
  final int id;
  final String title;
  final int chapterNumber;
  final int durationSeconds;
  final FileDto? file;

  AudioChapterResponse({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.durationSeconds,
    this.file,
  });

  factory AudioChapterResponse.fromJson(Map<String, dynamic> json) {
    return AudioChapterResponse(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      chapterNumber: json['chapterNumber'] ?? 0,
      durationSeconds: json['durationSeconds'] ?? 0,
      file: json['file'] is Map<String, dynamic>
          ? FileDto.fromJson(json['file'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AdminBookResponse {
  final int id;
  final String name;
  final String author;
  final String description;
  final FileDto? coverFile;
  final List<BookCategoryItemResponse> categories;
  final List<EbookChapterResponse> ebookChapters;
  final List<AudioChapterResponse> audioChapters;
  final List<FileDto> descriptionImages;

  AdminBookResponse({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    this.coverFile,
    required this.categories,
    required this.ebookChapters,
    required this.audioChapters,
    required this.descriptionImages,
  });

  factory AdminBookResponse.fromJson(Map<String, dynamic> json) {
    return AdminBookResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      coverFile: json['coverFile'] is Map<String, dynamic>
          ? FileDto.fromJson(json['coverFile'] as Map<String, dynamic>)
          : null,
      categories: (json['categories'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BookCategoryItemResponse.fromJson)
          .toList(),
      ebookChapters: (json['ebookChapters'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(EbookChapterResponse.fromJson)
          .toList(),
      audioChapters: (json['audioChapters'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AudioChapterResponse.fromJson)
          .toList(),
      descriptionImages: (json['descriptionImages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FileDto.fromJson)
          .toList(),
    );
  }

  String? get coverUrl {
    return coverFile?.filePath;
  }
}
