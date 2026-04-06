class AdminBookSearchRequest {
  final String? keyword;
  final int page;
  final int size;

  AdminBookSearchRequest({
    this.keyword,
    this.page = 0,
    this.size = 20,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      if (keyword != null && keyword!.trim().isNotEmpty) 'keyword': keyword!.trim(),
      'page': page.toString(),
      'size': size.toString(),
    };
  }
}
