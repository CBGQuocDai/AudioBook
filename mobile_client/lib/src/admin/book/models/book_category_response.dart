class BookCategoryResponse {
  final int id;
  final String name;
  final String description;

  BookCategoryResponse({
    required this.id,
    required this.name,
    required this.description,
  });

  factory BookCategoryResponse.fromJson(Map<String, dynamic> json) {
    return BookCategoryResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
