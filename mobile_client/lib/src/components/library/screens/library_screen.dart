import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/components/audioBook/model/audio_book_chapter_model.dart';
import 'package:mobile_client/src/components/audioBook/model/audio_book_route_args.dart';
import 'package:mobile_client/src/components/book_detail/model/book_detail_model.dart';
import 'package:mobile_client/src/components/library/models/audio_progress_response.dart';
import 'package:mobile_client/src/components/library/models/client_response.dart';
import 'package:mobile_client/src/components/library/models/purchased_book_response.dart';
import 'package:mobile_client/src/components/library/services/library_api_service.dart';
import 'package:mobile_client/src/components/reading/model/reading_chapter_model.dart';
import 'package:mobile_client/src/components/reading/model/reading_route_args.dart';
import 'package:mobile_client/src/home/models/book_response.dart';
import 'package:mobile_client/src/components/book_detail/model/book_detail_route_args.dart';
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
  bool _isLoadingRecent = false;

  List<AudioProgressResponse> _recentProgress = [];

  final int _selectedTabIndex = 2; // Library Tab Index

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
    _loadRecentProgress(token);
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



  Future<void> _loadRecentProgress(String token) async {
    setState(() {
      _isLoadingRecent = true;
    });
    try {
      final items = await _apiService.getRecentAudioProgress(token: token, size: 10);
      if (mounted) {
        setState(() {
          _recentProgress = items;
        });
      }
    } catch (_) {
      // Silent fail — section sẽ ẩn nếu rỗng
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecent = false;
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
    // Ẩn section nếu không có data và không loading
    if (!_isLoadingRecent && _recentProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: const Text(
            'Nghe gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: _isLoadingRecent
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentProgress.length,
                  itemBuilder: (context, index) {
                    final item = _recentProgress[index];
                    return _buildRecentCard(item);
                  },
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRecentCard(AudioProgressResponse item) {
    final percent = (item.progressPercent ?? 0.0).clamp(0.0, 100.0);
    final coverUrl = item.bookCoverUrl;
    final bookId = item.bookId;

    return GestureDetector(
      onTap: () => _openAudioPlayer(item),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with headphone overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          width: 130,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildRecentPlaceholder(),
                          errorWidget: (_, __, ___) => _buildRecentPlaceholder(),
                        )
                      : _buildRecentPlaceholder(),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headphones, color: Colors.orange, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100.0,
                minHeight: 4,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(height: 5),
            // Title
            Text(
              item.bookName ?? 'Không có tên',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            // Chapter info
            Text(
              item.chapterTitle != null
                  ? 'Chương ${item.chapterNumber ?? ''}: ${item.chapterTitle}'
                  : '${percent.toStringAsFixed(0)}% hoàn thành',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _openAudioPlayer(AudioProgressResponse item) {
    final filePath = item.chapterFilePath ?? '';
    if (filePath.isEmpty || item.bookId == null) return;

    final chapter = AudioBookChapterModel(
      id: item.chapterId ?? 0,
      title: item.chapterTitle ?? 'Chương ${item.chapterNumber ?? 1}',
      chapterNumber: item.chapterNumber ?? 1,
      filePath: filePath,
      fileName: item.chapterFileName ?? 'audio.mp3',
      durationSeconds: item.chapterDurationSeconds ?? 0,
    );

    final args = AudioBookRouteArgs(
      bookId: item.bookId!,
      bookTitle: item.bookName ?? 'Audio Book',
      author: item.bookAuthor ?? '',
      coverUrl: item.bookCoverUrl,
      chapters: [chapter],
      initialChapterIndex: 0,
      isRead: 1,
    );

    Navigator.pushNamed(context, AppRoutes.audioBook, arguments: args);
  }

  /// Fetch ebook progress + book detail rồi navigate thẳng vào ReadingScreen
  Future<void> _openReading(int bookId) async {
    final token = await _tokenStorageService.getToken();
    if (token == null || token.isEmpty) return;

    // Fetch song song progress và book detail
    final results = await Future.wait([
      _apiService.getEbookProgressForBook(token: token, bookId: bookId),
      _apiService.getBookDetailRaw(token: token, bookId: bookId),
    ]);

    final progress = results[0] as dynamic; // EbookProgressResponse?
    final bookRaw = results[1] as Map<String, dynamic>?;

    if (!mounted) return;

    if (bookRaw == null) {
      // Fall back sang book detail screen nếu không fetch được
      Navigator.pushNamed(context, AppRoutes.bookDetailPreview, arguments: bookId);
      return;
    }

    final bookDetail = BookDetailModel.fromJson(bookRaw);
    final ebookChapters = bookDetail.ebookChapters;

    if (ebookChapters.isEmpty) {
      Navigator.pushNamed(context, AppRoutes.bookDetailPreview, arguments: bookId);
      return;
    }

    // Build danh sách chapters có file PDF hợp lệ
    final chapters = <ReadingChapterModel>[];
    for (final ch in ebookChapters) {
      final fp = ch.file?.filePath ?? '';
      if (fp.trim().isEmpty) continue;
      chapters.add(ReadingChapterModel(
        id: ch.id,
        title: ch.title,
        chapterNumber: ch.chapterNumber,
        filePath: fp,
        fileName: ch.file?.fileName ?? 'chapter_${ch.chapterNumber}.pdf',
      ));
    }

    if (chapters.isEmpty) {
      Navigator.pushNamed(context, AppRoutes.bookDetailPreview, arguments: bookId);
      return;
    }

    // Tìm chapter đang đọc dở theo chapterId từ progress
    int initialIndex = 0;
    if (progress != null) {
      final int? chapterId = (progress as dynamic).chapterId as int?;
      if (chapterId != null) {
        final idx = chapters.indexWhere(
          (c) => c.id == chapterId,
        );
        if (idx >= 0) initialIndex = idx;
      }
    }

    Navigator.pushNamed(
      context,
      AppRoutes.reading,
      arguments: ReadingRouteArgs(
        bookId: bookId,
        chapters: chapters,
        initialChapterIndex: initialIndex,
        isRead: 1,
      ),
    );
  }

  Widget _buildRecentPlaceholder() {
    return Container(
      width: 130,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.headphones, color: Colors.grey, size: 36),
      ),
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
          isPurchased: book.isRead == 1,
        );
      },
    );
  }

  Widget _buildListItem({required int id, required String title, required String author, String? coverUrl, bool isPurchased = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.bookDetail,
          arguments: BookDetailRouteArgs(
            bookId: id,
            isRead: isPurchased ? 1 : 0,
          ),
        );
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
                    onPressed: isPurchased
                        ? () => _openReading(id)
                        : () => Navigator.pushNamed(context, AppRoutes.bookDetailPreview, arguments: id),
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
                              Icon(Icons.menu_book, size: 16),
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

        if (index == 0) { // Discovery/Khám phá
          Navigator.pushReplacementNamed(context, AppRoutes.discovery);
          return;
        }

        if (index == 1) { // Buy Credit
          await Navigator.pushNamed(context, AppRoutes.buyCredit);
          return;
        }

        if (index == 3) { // Profile
          Navigator.pushNamed(context, AppRoutes.profile);
          return;
        }
      },
      items: [
        _buildBottomNavItem(Icons.explore_outlined, 'Khám phá', 0),
        _buildBottomNavItem(Icons.add_circle_outline, 'Mua Credit', 1),
        _buildBottomNavItem(Icons.library_books_outlined, 'Thư viện', 2),
        _buildBottomNavItem(Icons.person_outline, 'Hồ sơ', 3),
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
