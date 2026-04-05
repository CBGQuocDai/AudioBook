import 'package:mobile_client/src/home/models/book_response.dart';

class BooksPageResponse {
  final List<BookResponse> content;
  final int totalPages;
  final int totalElements;
  final int currentPage;
  final int pageSize;

  BooksPageResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
    required this.pageSize,
  });

  factory BooksPageResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> contentList = json['content'] ?? [];
    return BooksPageResponse(
      content: contentList
          .map((item) => BookResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      currentPage: json['number'] ?? 0,
      pageSize: json['size'] ?? 0,
    );
  }
}
