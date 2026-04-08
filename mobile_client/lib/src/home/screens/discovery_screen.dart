import 'package:flutter/material.dart';
import 'package:mobile_client/src/home/models/book_response.dart';
import 'package:mobile_client/src/home/service/discovery_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/payment/screens/buy_credit_screen.dart';
import 'package:mobile_client/src/util/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  int _selectedTabIndex = 1; // Discovery tab
  static const String _recentSearchesKey = 'recent_searches_history';

  final List<String> _recentSearches = [];
  List<BookResponse> _trendingBooks = [];
  List<BookResponse> _newBooks = [];

  bool _isLoadingTrending = false;
  bool _isLoadingNew = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadBooks();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_recentSearchesKey) ?? [];
    setState(() {
      _recentSearches.clear();
      _recentSearches.addAll(history);
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
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
        size: 10,
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

    // Update local history
    final trimmedKey = keyword.trim();
    setState(() {
      _recentSearches.remove(trimmedKey);
      _recentSearches.insert(0, trimmedKey);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    });
    await _saveRecentSearches();

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      AppRoutes.searchResults,
      arguments: trimmedKey,
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
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 16),
              if (_recentSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildRecentSearches(),
                ),
              const SizedBox(height: 32),
              _buildTrendingSection(),
              const SizedBox(height: 32),
              _buildNewArrivalsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tiêu đề, tác giả...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
          suffixIcon: Icon(Icons.mic, color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: _searchBooks,
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
              'Tìm kiếm gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _recentSearches.clear();
                  _saveRecentSearches();
                });
              },
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 14, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Text(
                      _recentSearches[index],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Thịnh hành',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.trending),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingTrending
            ? const Center(child: CircularProgressIndicator())
            : _trendingBooks.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _trendingBooks.length,
                      itemBuilder: (context, index) {
                        return _buildBookCard(_trendingBooks[index], index);
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
                'Mới phát hành',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingNew
            ? const Center(child: CircularProgressIndicator())
            : _newBooks.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _newBooks.length,
                      itemBuilder: (context, index) {
                        return _buildNewArrivalCard(_newBooks[index]);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: book.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: book.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          index % 2 == 0 ? Icons.headphones : Icons.menu_book,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            book.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 14),
              const SizedBox(width: 4),
              Text(
                '4.${index + 5}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalCard(BookResponse book) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.bookDetail,
        arguments: book.id,
      ),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      width: 70,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 70,
                      height: 90,
                      color: Colors.grey[900],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    book.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up, color: Colors.orange, size: 12),
                        const SizedBox(width: 4),
                        const Text(
                          'Mới nhất',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF171B25),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Row(
          children: [
            _navItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Trang chủ', index: 0),
            _navItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Khám phá', index: 1),
            _navItem(icon: Icons.add_circle_outline, selectedIcon: Icons.add_circle, label: 'Mua Credit', index: 2),
            _navItem(icon: Icons.library_books_outlined, selectedIcon: Icons.library_books, label: 'Thư viện', index: 3),
            _navItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Hồ sơ', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 24,
              color: isSelected ? const Color(0xFFFFA321) : const Color(0xFF8D93A6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFFA321) : const Color(0xFF8D93A6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


