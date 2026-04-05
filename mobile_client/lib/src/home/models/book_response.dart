class BookResponse {
  final int id;
  final String name;
  final String author;
  final String description;
  final String? coverUrl;
  final double? rating;
  final int? reviewCount;
  final double? price;

  BookResponse({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    this.coverUrl,
    this.rating,
    this.reviewCount,
    this.price,
  });

  factory BookResponse.fromJson(Map<String, dynamic> json) {
    String? coverUrl;

    if (json['coverFile'] != null) {
      final coverFile = json['coverFile'];
      if (coverFile is Map<String, dynamic>) {
        coverUrl = coverFile['fileUrl'] ?? coverFile['filePath'];
      }
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
