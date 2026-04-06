import 'chapter_request.dart';

class CreateBookRequest {
  final String name;
  final String? author;
  final String? description;
  final int? coverFileId;
  final List<int> categoryIds;
  final List<EbookChapterRequest> ebookChapters;
  final List<AudioChapterRequest> audioChapters;
  final List<int> descriptionImageFileIds;

  CreateBookRequest({
    required this.name,
    this.author,
    this.description,
    this.coverFileId,
    required this.categoryIds,
    required this.ebookChapters,
    required this.audioChapters,
    required this.descriptionImageFileIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'author': author,
      'description': description,
      'coverFileId': coverFileId,
      'categoryIds': categoryIds,
      'ebookChapters': ebookChapters.map((e) => e.toJson()).toList(),
      'audioChapters': audioChapters.map((e) => e.toJson()).toList(),
      'descriptionImageFileIds': descriptionImageFileIds,
    };
  }
}

class UpdateBookRequest {
  final String name;
  final String? author;
  final String? description;
  final int? coverFileId;
  final List<int> categoryIds;
  final List<EbookChapterRequest> ebookChapters;
  final List<AudioChapterRequest> audioChapters;
  final List<int> descriptionImageFileIds;

  UpdateBookRequest({
    required this.name,
    this.author,
    this.description,
    this.coverFileId,
    required this.categoryIds,
    required this.ebookChapters,
    required this.audioChapters,
    required this.descriptionImageFileIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'author': author,
      'description': description,
      'coverFileId': coverFileId,
      'categoryIds': categoryIds,
      'ebookChapters': ebookChapters.map((e) => e.toJson()).toList(),
      'audioChapters': audioChapters.map((e) => e.toJson()).toList(),
      'descriptionImageFileIds': descriptionImageFileIds,
    };
  }
}
