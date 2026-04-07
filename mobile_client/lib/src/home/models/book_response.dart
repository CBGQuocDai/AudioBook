class EbookChapter {
  final int id;
  final String title;
  final int chapterNumber;

  EbookChapter({
    required this.id,
    required this.title,
    required this.chapterNumber,
  });

  factory EbookChapter.fromJson(Map<String, dynamic> json) {
    return EbookChapter(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      chapterNumber: json['chapterNumber'] ?? 0,
    );
  }
}

class BookResponse {
  final int id;
  final String name;
  final String author;
  final String description;
  final String? coverUrl;
  final double? rating;
  final int? reviewCount;
  final double? price;
  final List<String> categories;
  final List<EbookChapter> ebookChapters;

  BookResponse({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    this.coverUrl,
    this.rating,
    this.reviewCount,
    this.price,
    this.categories = const [],
    this.ebookChapters = const [],
  });

  factory BookResponse.fromJson(Map<String, dynamic> json) {
    String? coverUrl;

    if (json['coverFile'] != null) {
      final coverFile = json['coverFile'];
      if (coverFile is Map<String, dynamic>) {
        coverUrl = coverFile['fileUrl'] ?? coverFile['filePath'];
      }
    }

    List<String> parsedCategories = [];
    if (json['categories'] != null && json['categories'] is List) {
      parsedCategories = (json['categories'] as List).map((c) {
        if (c is Map) return c['name']?.toString() ?? '';
        return c.toString();
      }).where((c) => c.isNotEmpty).toList();
    }

    List<EbookChapter> parsedChapters = [];
    if (json['ebookChapters'] != null && json['ebookChapters'] is List) {
      parsedChapters = (json['ebookChapters'] as List)
          .whereType<Map<String, dynamic>>()
          .map((c) => EbookChapter.fromJson(c))
          .toList();
    }

    return BookResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      coverUrl: coverUrl,
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['reviewCount']),
      price: _parseDouble(json['price']),
      categories: parsedCategories,
      ebookChapters: parsedChapters,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'description': description,
      'coverFile': {
        'filePath': coverUrl,
      },
      'rating': rating,
      'reviewCount': reviewCount,
      'price': price,
    };
  }
}
