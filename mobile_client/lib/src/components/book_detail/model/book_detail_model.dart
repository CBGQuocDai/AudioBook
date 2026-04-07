class BookFileModel {
  final int id;
  final String filePath;
  final String fileName;

  const BookFileModel({
    required this.id,
    required this.filePath,
    required this.fileName,
  });

  factory BookFileModel.fromJson(Map<String, dynamic> json) {
    return BookFileModel(
      id: _asInt(json['id']),
      filePath: (json['filePath'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
    );
  }
}

class BookCategoryModel {
  final int id;
  final String name;

  const BookCategoryModel({
    required this.id,
    required this.name,
  });

  factory BookCategoryModel.fromJson(Map<String, dynamic> json) {
    return BookCategoryModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class EbookChapterModel {
  final int id;
  final String title;
  final int chapterNumber;
  final BookFileModel? file;

  const EbookChapterModel({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.file,
  });

  factory EbookChapterModel.fromJson(Map<String, dynamic> json) {
    final rawFile = json['file'];
    return EbookChapterModel(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      chapterNumber: _asInt(json['chapterNumber']),
      file: rawFile is Map<String, dynamic> ? BookFileModel.fromJson(rawFile) : null,
    );
  }
}

class AudioChapterModel {
  final int id;
  final String title;
  final int chapterNumber;
  final int durationSeconds;
  final BookFileModel? file;

  const AudioChapterModel({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.durationSeconds,
    required this.file,
  });

  factory AudioChapterModel.fromJson(Map<String, dynamic> json) {
    final rawFile = json['file'];
    return AudioChapterModel(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      chapterNumber: _asInt(json['chapterNumber']),
      durationSeconds: _asInt(json['durationSeconds']),
      file: rawFile is Map<String, dynamic> ? BookFileModel.fromJson(rawFile) : null,
    );
  }
}

class BookDetailModel {
  final int id;
  final String name;
  final String author;
  final String description;
  final BookFileModel? coverFile;
  final List<BookCategoryModel> categories;
  final List<EbookChapterModel> ebookChapters;
  final List<AudioChapterModel> audioChapters;
  final List<BookFileModel> descriptionImages;
  final int isRead;
  final int? ebookProgressChapterNumber;
  final int? audioProgressChapterNumber;

  const BookDetailModel({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.coverFile,
    required this.categories,
    required this.ebookChapters,
    required this.audioChapters,
    required this.descriptionImages,
    required this.isRead,
    required this.ebookProgressChapterNumber,
    required this.audioProgressChapterNumber,
  });

  bool get canRead => isRead == 1;

  factory BookDetailModel.fromJson(Map<String, dynamic> json) {
    final rawCover = json['coverFile'];

    return BookDetailModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      coverFile: rawCover is Map<String, dynamic> ? BookFileModel.fromJson(rawCover) : null,
      categories: _asList(json['categories'])
          .whereType<Map<String, dynamic>>()
          .map(BookCategoryModel.fromJson)
          .toList(),
      ebookChapters: _asList(json['ebookChapters'])
          .whereType<Map<String, dynamic>>()
          .map(EbookChapterModel.fromJson)
          .toList(),
      audioChapters: _asList(json['audioChapters'])
          .whereType<Map<String, dynamic>>()
          .map(AudioChapterModel.fromJson)
          .toList(),
      descriptionImages: _asList(json['descriptionImages'])
          .whereType<Map<String, dynamic>>()
          .map(BookFileModel.fromJson)
          .toList(),
      isRead: _asIsRead(json['isRead']),
      ebookProgressChapterNumber: _parseProgressChapterNumber(
        json,
        const [
          'ebookProgressChapterNumber',
          'ebookCurrentChapterNumber',
          'readingChapterNumber',
          'ebookCurrentChapter',
        ],
      ),
      audioProgressChapterNumber: _parseProgressChapterNumber(
        json,
        const [
          'audioProgressChapterNumber',
          'audioCurrentChapterNumber',
          'listeningChapterNumber',
          'audioCurrentChapter',
        ],
      ),
    );
  }
}

int? _parseProgressChapterNumber(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }

    final value = json[key];
    if (value == null) {
      continue;
    }

    if (value is Map<String, dynamic>) {
      final nested = value['chapterNumber'] ?? value['number'];
      final parsedNested = _asInt(nested);
      if (parsedNested > 0) {
        return parsedNested;
      }
      continue;
    }

    final parsed = _asInt(value);
    if (parsed > 0) {
      return parsed;
    }
  }

  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int _asIsRead(dynamic value) {
  if (value is bool) {
    return value ? 1 : 0;
  }
  return _asInt(value) == 1 ? 1 : 0;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const [];
}