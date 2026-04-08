import 'package:flutter/material.dart';
import 'package:mobile_client/src/home/models/book_response.dart';
import 'package:mobile_client/src/home/service/discovery_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/payment/screens/buy_credit_screen.dart';
import 'package:mobile_client/src/util/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: DiscoveryApiService.defaultBaseUrl,
  );

  final DiscoveryApiService _discoveryApiService =
      DiscoveryApiService(baseUrl: _baseUrl);
  final TokenStorageService _tokenStorageService = TokenStorageService();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Fiction', 'Self-Help', 'Sci-Fi'];
  String _selectedCategory = 'All';
  int _selectedTabIndex = 1; // Discovery tab

  final List<String> _recentSearches = ['Dune Messiah', 'Malcolm Gladwell'];
  List<BookResponse> _trendingBooks = [];
  List<BookResponse> _newBooks = [];

  bool _isLoadingTrending = false;
  bool _isLoadingNew = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    await _loadTrendingBooks();
    await _loadNewArrivals();
  }

  Future<void> _loadTrendingBooks() async {
    setState(() {
      _isLoadingTrending = true;
    });

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const DiscoveryApiException(
            'Không tìm thấy token, vui lòng đăng nhập lại.');
      }

      final response = await _discoveryApiService.getTrendingBooks(
        token: token,
        page: 0,
        size: 4,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _trendingBooks = response.data?.content ?? [];
      });
    } on DiscoveryApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrending = false;
        });
      }
    }
  }

  Future<void> _loadNewArrivals() async {
    setState(() {
      _isLoadingNew = true;
    });

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const DiscoveryApiException(
            'Không tìm thấy token, vui lòng đăng nhập lại.');
      }

      final response = await _discoveryApiService.getNewArrivals(
        token: token,
        page: 0,
        size: 4,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _newBooks = response.data?.content ?? [];
      });
    } on DiscoveryApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNew = false;
        });
      }
    }
  }

  Future<void> _searchBooks(String keyword) async {
    if (keyword.trim().isEmpty) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.searchResults,
      arguments: keyword.trim(),
    );
  }

  Future<void> _onBottomNavTap(int index) async {
    if (index == 2) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BuyCreditScreen(),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedTabIndex = 1;
      });
      return;
    }

    if (index == 4) {
      await Navigator.pushNamed(context, AppRoutes.profile);
      if (!mounted) return;
      setState(() {
        _selectedTabIndex = 1;
      });
      return;
    }

    if (index == 3) {
      await Navigator.pushNamed(context, AppRoutes.library);
      if (!mounted) return;
      setState(() {
        _selectedTabIndex = 1;
      });
      return;
    }

    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSearchBar(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCategoryFilter(),
              ),
              const SizedBox(height: 24),
              if (_recentSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildRecentSearches(),
                ),
              const SizedBox(height: 24),
              _buildTrendingSection(),
              const SizedBox(height: 24),
              _buildNewArrivalsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search titles, authors, or narrators...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onSubmitted: _searchBooks,
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

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _recentSearches.clear();
                });
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: _recentSearches
              .map(
                (search) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(search),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _recentSearches.remove(search);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trending Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.trending),
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _isLoadingTrending
            ? const Center(child: CircularProgressIndicator())
            : _trendingBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.grey, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage ?? 'Không có dữ liệu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _trendingBooks.length,
                      itemBuilder: (context, index) {
                        final book = _trendingBooks[index];
                        return _buildBookCard(book, index);
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildNewArrivalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Arrivals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _isLoadingNew
            ? const Center(child: CircularProgressIndicator())
            : _newBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.grey, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage ?? 'Không có dữ liệu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _newBooks.length,
                      itemBuilder: (context, index) {
                        final book = _newBooks[index];
                        return _buildNewArrivalCard(book);
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildBookCard(BookResponse book, int index) {
    return GestureDetector(
        onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.bookDetail,
              arguments: book.id,
            ),
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            width: 160,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 160,
                              height: 200,
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 160,
                              height: 200,
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            width: 160,
                            height: 200,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.bookmark,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                book.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '4.${index + 5}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildNewArrivalCard(BookResponse book) {
    return GestureDetector(
        onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.bookDetail,
              arguments: book.id,
            ),
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            width: 140,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 140,
                              height: 100,
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 140,
                              height: 100,
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 100,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.bookmark,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                '★ Best Seller',
                style: TextStyle(fontSize: 8, color: Colors.orange),
              ),
            ],
          ),
        ));
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF171B25),
          border: Border(top: BorderSide(color: Color(0x2FFFFFFF))),
        ),
        child: Row(
          children: [
            _navItem(icon: Icons.home_outlined, label: 'Home', index: 0),
            _navItem(
                icon: Icons.explore_outlined, label: 'Discovery', index: 1),
            _navItem(
                icon: Icons.add_circle_outline, label: 'Buy Credit', index: 2),
            _navItem(
                icon: Icons.library_books_outlined, label: 'Library', index: 3),
            _navItem(icon: Icons.person_outline, label: 'Profile', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFFFFA321)
                  : const Color(0xFF8D93A6),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFFFA321)
                    : const Color(0xFF8D93A6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
