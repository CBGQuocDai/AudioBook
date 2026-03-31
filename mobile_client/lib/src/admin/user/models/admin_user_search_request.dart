class AdminUserSearchRequest {
  final String? keyword;
  final int page;
  final int size;
  final String? sort;

  AdminUserSearchRequest({
    this.keyword,
    this.page = 0,
    this.size = 10,
    this.sort,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      if (keyword != null && keyword!.trim().isNotEmpty) 'keyword': keyword!.trim(),
      'page': page.toString(),
      'size': size.toString(),
      if (sort != null && sort!.trim().isNotEmpty) 'sort': sort!.trim(),
    };
  }
}