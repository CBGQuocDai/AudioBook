import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'provider/book_detail_preview_provider.dart';
import '../../home/models/book_response.dart';

class BookDetailPreviewScreen extends StatelessWidget {
  final int bookId;

  const BookDetailPreviewScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookDetailPreviewProvider()..fetchBookDetails(bookId),
      child: Scaffold(
        backgroundColor: const Color(0xFF151515),
        body: SafeArea(
          child: Stack(
            children: [
              const _BookDetailContent(),
              
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(
                        Icons.arrow_back,
                        () => Navigator.pop(context),
                      ),
                      _buildIconButton(
                        Icons.bookmark_border,
                        () {},
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: const _BottomBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}

class _BookDetailContent extends StatelessWidget {
  const _BookDetailContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookDetailPreviewProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final book = provider.book;
    if (book == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 160), // Increased padding to prevent overlap with bottom bar
      child: Column(
        children: [
          const SizedBox(height: 48), // Spacing from top bar
          _buildCoverImage(book),
          const SizedBox(height: 24),
          _buildTitleAndAuthor(book),
          const SizedBox(height: 16),
          _buildRatingAndCategories(book),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
          const _TabsSection(),
          const SizedBox(height: 16),
          provider.currentTab == 0 ? _buildAboutSection(book, provider) : _buildChaptersSection(book),
          const SizedBox(height: 24),
          _buildSpecs(book),
          const SizedBox(height: 32),
          const _YouMayAlsoLikeSection(),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BookResponse book) {
    return Container(
      height: 280,
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: book.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: book.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.book, size: 50, color: Colors.grey),
                ),
              )
            : Container(
                color: Colors.grey[800],
                child: const Icon(Icons.book, size: 50, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildTitleAndAuthor(BookResponse book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            book.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Tác giả ",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              Text(
                book.author,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingAndCategories(BookResponse book) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star, color: Colors.orange, size: 18),
        const SizedBox(width: 4),
        Text(
          "${book.rating?.toStringAsFixed(1) ?? '4.5'} (${book.reviewCount ?? '0'})",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text("|", style: TextStyle(color: Colors.grey)),
        ),
        if (book.categories.isNotEmpty)
          ...book.categories.take(2).map((cat) => _buildCategoryChip(cat)).toList()
        else
          ...['FICTION', 'FANTASY'].map((cat) => _buildCategoryChip(cat)).toList(),
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.menu_book, color: Colors.black),
              label: const Text(
                "Đọc thử",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.headphones, color: Colors.white),
              label: const Text(
                "Nghe thử",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BookResponse book, BookDetailPreviewProvider provider) {
    final isExpanded = provider.isDescriptionExpanded;
    final text = book.description.isNotEmpty 
        ? book.description 
        : "Giữa sự sống và cái chết là một thư viện, và trong thư viện đó, các kệ chứa đi mãi mãi. Mỗi cuốn sách cung cấp một cơ hội để thử xem một cuộc đời khác mà bạn có thể đã sống... ";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
              fontSize: 14,
            ),
            maxLines: isExpanded ? null : 6,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => provider.toggleDescription(),
            child: Row(
              children: [
                Text(
                  isExpanded ? "Thu gọn" : "Xem thêm",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                  color: Colors.orange, 
                  size: 18
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersSection(BookResponse book) {
    if (book.ebookChapters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Text(
            "Đang cập nhật chương sách...",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        itemCount: book.ebookChapters.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, i) {
          final chapter = book.ebookChapters[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text("${i + 1}".padLeft(2, '0'), style: const TextStyle(color: Colors.grey)),
            title: Text(chapter.title, style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.play_circle_outline, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildSpecs(BookResponse book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSpecItem("Trang", "288"),
          _buildSpecItem("Ngôn ngữ", "VIE"),
          _buildSpecItem("Âm thanh", "9 giờ 20 phút"),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String title, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TabsSection extends StatelessWidget {
  const _TabsSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookDetailPreviewProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(child: _buildTab("Giới thiệu", 0, provider)),
            Expanded(child: _buildTab("Chương", 1, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index, BookDetailPreviewProvider provider) {
    final isSelected = provider.currentTab == index;
    return GestureDetector(
      onTap: () => provider.changeTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _YouMayAlsoLikeSection extends StatelessWidget {
  const _YouMayAlsoLikeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Có thể bạn cũng thích",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Xem tất cả",
                style: TextStyle(color: Colors.orange[300], fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.book, color: Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "The Alchemist",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      "Paulo Coelho",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookDetailPreviewProvider>();
    final book = provider.book;
    final priceStr = book?.price != null ? '\$${book!.price}' : 'Credit';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: const Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Mở khoá",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priceStr,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
