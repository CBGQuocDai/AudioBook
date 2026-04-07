class PurchasedBookResponse {
  final int id;
  final int bookId;
  final String bookName;
  final String bookAuthor;
  final String? coverUrl;
  final DateTime? purchasedAt;
  final bool? isActive;
  final bool? expired;

  PurchasedBookResponse({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.bookAuthor,
    this.coverUrl,
    this.purchasedAt,
    this.isActive,
    this.expired,
  });

  factory PurchasedBookResponse.fromJson(Map<String, dynamic> json) {
    String? finalCoverUrl;
    
    if (json['coverFile'] != null) {
      final coverFile = json['coverFile'];
      if (coverFile is Map<String, dynamic>) {
        finalCoverUrl = coverFile['fileUrl'] ?? coverFile['filePath'];
      }
    }

    DateTime? parsedDate;
    if (json['purchasedAt'] != null) {
      parsedDate = DateTime.tryParse(json['purchasedAt'].toString());
    }

    return PurchasedBookResponse(
      id: json['id'] ?? 0,
      bookId: json['bookId'] ?? 0,
      bookName: json['bookName'] ?? '',
      bookAuthor: json['bookAuthor'] ?? '',
      coverUrl: finalCoverUrl,
      purchasedAt: parsedDate,
      isActive: json['isActive'],
      expired: json['expired'],
    );
  }
}
