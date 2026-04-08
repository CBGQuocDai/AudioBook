import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/components/library/models/client_response.dart';
import 'package:mobile_client/src/components/library/models/purchased_book_response.dart';
import 'package:mobile_client/src/components/library/services/library_api_service.dart';
import 'package:mobile_client/src/home/models/book_response.dart';
import 'package:mobile_client/src/payment/screens/buy_credit_screen.dart';
import 'package:mobile_client/src/util/routes.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  final LibraryApiService _apiService = LibraryApiService(baseUrl: LibraryApiService.defaultBaseUrl);
  final TokenStorageService _tokenStorageService = TokenStorageService();

  late TabController _tabController;

  ClientResponse? _clientProfile;
  List<BookResponse> _favouriteBooks = [];
  List<PurchasedBookResponse> _purchasedBooks = [];

  bool _isLoadingFavourites = false;
  bool _isLoadingPurchased = false;

  final int _selectedTabIndex = 3; // Library Tab Index

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = await _tokenStorageService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
      return;
    }
    _loadProfile(token);
    _loadFavourites(token);
    _loadPurchased(token);
  }

  Future<void> _loadProfile(String token) async {
    try {
      final response = await _apiService.getClientProfile(token: token);
      if (mounted) {
        setState(() {
          _clientProfile = response.data;
        });
      }
    } catch (e) {
      // Handle error gracefully
    }
  }

  Future<void> _loadFavourites(String token) async {
    setState(() {
      _isLoadingFavourites = true;
    });
    try {
      final response = await _apiService.getFavouriteBooks(token: token);
      if (mounted) {
        setState(() {
          _favouriteBooks = response.data ?? [];
        });
      }
    } catch (e) {
      // Handle error gracefully
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavourites = false;
        });
      }
    }
  }

  Future<void> _loadPurchased(String token) async {
    setState(() {
      _isLoadingPurchased = true;
    });
    try {
      final response = await _apiService.getPurchasedBooks(token: token, page: 0, size: 50);
      if (mounted) {
        setState(() {
          _purchasedBooks = response.data?.content ?? [];
        });
      }
    } catch (e) {
      // Handle error gracefully
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPurchased = false;
        });
      }
    }
  }



  Future<void> _logout() async {
    await _tokenStorageService.clearToken();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414), // Dark background matching design
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: _clientProfile?.avatarUrl != null
                            ? CachedNetworkImageProvider(_clientProfile!.avatarUrl!)
                            : null,
                        child: _clientProfile?.avatarUrl == null
                            ? const Icon(Icons.person, size: 24)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xin chào,',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _clientProfile?.name ?? 'Đang tải...',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildRecentlyViewed(),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.orange,
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Đã mua'),
                      Tab(text: 'Yêu thích'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPurchasedTab(),
              _buildFavouritesTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildRecentlyViewed() {
    // Fake data for recently viewed
    final fakeBooks = [
      {'title': 'The Midnight Library', 'author': 'Matt Haig', 'color': Colors.teal},
      {'title': 'Atomic Habits', 'author': 'James Clear', 'color': Colors.brown[300]},
      {'title': 'Project Hail Mary', 'author': 'Andy Weir', 'color': Colors.amber},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đã xem gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: fakeBooks.length,
            itemBuilder: (context, index) {
              final book = fakeBooks[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: book['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          book['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    ),
                    Text(
                      book['author'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPurchasedTab() {
    if (_isLoadingPurchased) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_purchasedBooks.isEmpty) {
      return const Center(
        child: Text('Bạn chưa mua cuốn sách nào.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _purchasedBooks.length,
      itemBuilder: (context, index) {
        final book = _purchasedBooks[index];
        return _buildListItem(
          id: book.bookId,
          title: book.bookName,
          author: book.bookAuthor,
          coverUrl: book.coverUrl,
          isPurchased: true,
        );
      },
    );
  }

  Widget _buildFavouritesTab() {
    if (_isLoadingFavourites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favouriteBooks.isEmpty) {
      return const Center(
        child: Text('Bạn chưa có cuốn sách yêu thích nào.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favouriteBooks.length,
      itemBuilder: (context, index) {
        final book = _favouriteBooks[index];
        return _buildListItem(
          id: book.id,
          title: book.name,
          author: book.author,
          coverUrl: book.coverUrl,
        );
      },
    );
  }

  Widget _buildListItem({required int id, required String title, required String author, String? coverUrl, bool isPurchased = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.bookDetailPreview, arguments: id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 80,
                        color: Colors.grey[800],
                      ),
                      errorWidget: (context, url, error) => _buildPlaceholderCover(),
                    )
                  : _buildPlaceholderCover(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.bookDetailPreview, arguments: id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isPurchased
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Tiếp tục đọc'),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          )
                        : const Text('Xem chi tiết'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 60,
      height: 80,
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      unselectedItemColor: Colors.grey[700],
      selectedItemColor: Colors.orange,
      backgroundColor: const Color(0xFF1A1A1A),
      type: BottomNavigationBarType.fixed,
      onTap: (index) async {
        if (index == _selectedTabIndex) return;

        if (index == 0 || index == 1) { // Home & Discovery
          Navigator.pushReplacementNamed(context, AppRoutes.discovery);
          return;
        }

        if (index == 2) { // Buy Credit
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BuyCreditScreen(),
            ),
          );
          return;
        }

        if (index == 4) { // Profile
          Navigator.pushNamed(context, AppRoutes.profile);
          return;
        }
      },
      items: [
        _buildBottomNavItem(Icons.home_outlined, 'Trang chủ', 0),
        _buildBottomNavItem(Icons.explore_outlined, 'Khám phá', 1),
        _buildBottomNavItem(Icons.add_circle_outline, 'Mua Credit', 2),
        _buildBottomNavItem(Icons.library_books_outlined, 'Thư viện', 3),
        _buildBottomNavItem(Icons.person_outline, 'Hồ sơ', 4),
      ],
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Icon(
        icon == Icons.home_outlined
            ? Icons.home
            : icon == Icons.explore_outlined
                ? Icons.explore
                : icon == Icons.add_circle_outline
                    ? Icons.add_circle
                    : icon == Icons.library_books_outlined
                        ? Icons.library_books
                        : Icons.person,
      ),
      label: label,
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF141414),
      child: _tabBar,
    );
  }

  bool get holdSafeArea => false;
  
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
