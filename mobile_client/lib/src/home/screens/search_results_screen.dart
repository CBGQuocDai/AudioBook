import 'package:flutter/material.dart';
import 'package:mobile_client/src/home/models/book_response.dart';
import 'package:mobile_client/src/home/service/discovery_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_client/src/components/book_detail/model/book_detail_route_args.dart';
import 'package:mobile_client/src/util/routes.dart';

class SearchResultsScreen extends StatefulWidget {
  final String keyword;

  const SearchResultsScreen({
    super.key,
    required this.keyword,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: DiscoveryApiService.defaultBaseUrl,
  );

  final DiscoveryApiService _discoveryApiService =
      DiscoveryApiService(baseUrl: _baseUrl);
  final TokenStorageService _tokenStorageService = TokenStorageService();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['Tất cả', 'Sách', 'Sách nói', 'Tác giả'];
  String _selectedCategory = 'Tất cả';

  List<BookResponse> _searchResults = [];
  int _totalResults = 0;
  int _currentPage = 0;
  final int _pageSize = 20;

  bool _isLoading = false;
  String? _errorMessage;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.keyword;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _performSearch(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _searchResults.length < _totalResults) {
        _performSearch(_currentPage + 1);
      }
    }
  }

  Future<void> _performSearch(int page) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw DiscoveryApiException(
            'Không tìm thấy token, vui lòng đăng nhập lại.');
      }

      final response = await _discoveryApiService.searchBooks(
        keyword: _searchController.text.trim(),
        token: token,
        page: page,
        size: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (page == 0) {
          _searchResults = response.data?.content ?? [];
        } else {
          _searchResults.addAll(response.data?.content ?? []);
        }
        _totalResults = response.data?.totalElements ?? 0;
        _currentPage = page;
      });
    } on DiscoveryApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isNotEmpty) {
      _currentPage = 0;
      _performSearch(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả tìm kiếm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCategoryFilter(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'KẾT QUẢ TÌM KIẾM ($_totalResults)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm tiêu đề, tác giả, hoặc người đọc...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchResults.clear();
                    _totalResults = 0;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: _onSearchChanged,
      onSubmitted: (_) => _onSearchChanged(_searchController.text),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = category;
              });
            },
            backgroundColor: const Color(0xFF2C2C2C),
            selectedColor: Colors.orange,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
            ),
            side: BorderSide(
              color: isSelected ? Colors.orange : Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Không tìm thấy kết quả',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _searchResults.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final book = _searchResults[index];
        return _buildSearchResultItem(book);
      },
    );
  }

  Widget _buildSearchResultItem(BookResponse book) {
    final imageUrl = _safeImageUrl(book.coverUrl);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.bookDetail,
        arguments: BookDetailRouteArgs(
          bookId: book.id,
          isRead: book.isRead ?? 0,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 100,
                        height: 140,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 140,
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 140,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 140,
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SÁCH NÓI',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (book.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        book.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      if (book.reviewCount != null)
                        Text(
                          '(${_formatCount(book.reviewCount!)})',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 8),
                if (book.price != null)
                  Text(
                    '\$${book.price!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  String? _safeImageUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return trimmed;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return count.toString();
    }
  }
}
