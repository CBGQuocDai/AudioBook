import 'package:mobile_client/src/components/library/models/purchased_book_response.dart';

class PurchasedBooksPageResponse {
  final List<PurchasedBookResponse> content;
  final int totalPages;
  final int totalElements;
  final int currentPage;
  final int pageSize;

  PurchasedBooksPageResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
    required this.pageSize,
  });

  factory PurchasedBooksPageResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> contentList = json['content'] ?? [];
    return PurchasedBooksPageResponse(
      content: contentList
          .map((item) => PurchasedBookResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      currentPage: json['number'] ?? 0,
      pageSize: json['size'] ?? 0,
    );
  }
}
