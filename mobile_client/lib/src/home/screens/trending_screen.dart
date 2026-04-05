import 'package:flutter/material.dart';
import 'package:mobile_client/src/home/models/book_response.dart';
import 'package:mobile_client/src/home/service/discovery_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: DiscoveryApiService.defaultBaseUrl,
  );

  final DiscoveryApiService _discoveryApiService =
      DiscoveryApiService(baseUrl: _baseUrl);
  final TokenStorageService _tokenStorageService = TokenStorageService();

  final List<String> _tabs = ['Books', 'Audiobooks'];
  String _selectedTab = 'Books';

  List<BookResponse> _trendingBooks = [];
  List<BookResponse> _mostPurchased = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrendingData();
  }

  Future<void> _loadTrendingData() async {
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

      final trendingResponse = await _discoveryApiService.getTrendingBooks(
        token: token,
        page: 0,
        size: 10,
      );

      final purchasedResponse = await _discoveryApiService.getTrendingBooks(
        token: token,
        page: 0,
        size: 6,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _trendingBooks = trendingResponse.data?.content ?? [];
        _mostPurchased = purchasedResponse.data?.content ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildTabFilter(),
                    ),
                    const SizedBox(height: 24),
                    _buildWeeklyTop10Section(),
                    const SizedBox(height: 32),
                    _buildMostPurchasedSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTabFilter() {
    return Row(
      children: _tabs.map((tab) {
        final isSelected = _selectedTab == tab;
        return Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedTab = tab),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (isSelected)
                Container(
                  height: 3,
                  color: Colors.orange,
                )
              else
                const SizedBox(height: 3),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyTop10Section() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Top 10',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'UPDATES SUNDAY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(
              _trendingBooks.length,
              (index) => _buildTrendingItem(
                _trendingBooks[index],
                index + 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingItem(BookResponse book, int rank) {
    final isTopRank = rank == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            width: 80,
                            height: 110,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 110,
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 80,
                              height: 110,
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 110,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.trending_up,
                                color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatCount(_getRandomReads())} reads',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.star,
                                color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              book.rating?.toStringAsFixed(1) ?? '4.5',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: -8,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isTopRank ? Colors.orange : Color(0xFF4A5568),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isTopRank ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostPurchasedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Most Purchased',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _mostPurchased.length,
            itemBuilder: (context, index) {
              final book = _mostPurchased[index];
              return _buildMostPurchasedCard(book);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMostPurchasedCard(BookResponse book) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: book.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: book.coverUrl!,
                    width: 140,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 140,
                      height: 160,
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 140,
                      height: 160,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  )
                : Container(
                    width: 140,
                    height: 160,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            book.name,
            maxLines: 1,
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
          Text(
            '\$${book.price?.toStringAsFixed(2) ?? '14.99'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
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

  int _getRandomReads() {
    final random = Random();
    return 50000 + random.nextInt(150000);
  }
}
