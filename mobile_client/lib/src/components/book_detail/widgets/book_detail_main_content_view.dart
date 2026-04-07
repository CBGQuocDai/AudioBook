import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/book_detail_provider.dart';

class BookDetailMainContentView extends StatelessWidget {
  const BookDetailMainContentView({
    super.key,
    required this.isPreview,
  });

  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookDetailProvider>();
    final bottomPadding = isPreview ? 140.0 : 24.0;

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final book = provider.book;
    if (book == null) {
      return const Center(
        child: Text('Không có dữ liệu sách', style: TextStyle(color: Colors.white70)),
      );
    }

    final readButtonLabel = isPreview ? 'Đọc thử' : 'Đọc ngay';
    final listenButtonLabel = isPreview ? 'Nghe thử' : 'Nghe ngay';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 64, 24, bottomPadding),
      child: Column(
        children: [
          _CoverImage(url: provider.coverUrl),
          const SizedBox(height: 24),
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
          Text(
            book.author,
            style: const TextStyle(color: Colors.orange, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _MetaRow(categories: provider.categories),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => provider.openFirstEbook(context),
                  icon: const Icon(Icons.menu_book, color: Colors.black),
                  label: Text(
                    readButtonLabel,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => provider.openFirstAudio(context),
                  icon: const Icon(Icons.headphones, color: Colors.white),
                  label: Text(
                    listenButtonLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _Tabs(),
          const SizedBox(height: 16),
          _TabContent(provider: provider),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star, color: Colors.orange, size: 18),
        const SizedBox(width: 4),
        const Text('Chi tiết sách', style: TextStyle(color: Colors.white70)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('|', style: TextStyle(color: Colors.grey)),
        ),
        if (categories.isNotEmpty)
          ...categories.take(2).map((e) => _CategoryChip(label: e))
        else
          const _CategoryChip(label: 'BOOK'),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookDetailProvider>();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(child: _TabButton(title: 'Giới thiệu', index: 0, current: provider.currentTab)),
          Expanded(child: _TabButton(title: 'Ebook', index: 1, current: provider.currentTab)),
          Expanded(child: _TabButton(title: 'Audio', index: 2, current: provider.currentTab)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.index,
    required this.current,
  });

  final String title;
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final selected = current == index;
    return GestureDetector(
      onTap: () => context.read<BookDetailProvider>().changeTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: selected ? Colors.orange : Colors.transparent, width: 2),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.orange : Colors.white60,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.provider});

  final BookDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.currentTab == 0) {
      return _AboutSection(provider: provider);
    }

    if (provider.currentTab == 1) {
      return _ChapterList(
        titles: provider.ebookChapters.map((e) => e.title).toList(),
        trailingIcon: Icons.menu_book,
        onTap: (index) => provider.openEbookChapter(context, index),
      );
    }

    return _ChapterList(
      titles: provider.audioChapters.map((e) => e.title).toList(),
      trailingIcon: Icons.headphones,
      onTap: (index) => provider.openAudioChapter(context, index),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.provider});

  final BookDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final isExpanded = provider.isDescriptionExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.aboutText,
          style: const TextStyle(color: Colors.white70, height: 1.5),
          maxLines: isExpanded ? null : 6,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: provider.toggleDescription,
          child: Text(
            isExpanded ? 'Thu gọn' : 'Xem thêm',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        const _RatingSectionPlaceholder(),
        if (provider.descriptionImageUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.descriptionImageUrls.length,
              itemBuilder: (context, index) {
                final url = provider.descriptionImageUrls[index];
                return GestureDetector(
                  onTap: () => provider.openImage(context, url),
                  child: Container(
                    width: 280,
                    margin: EdgeInsets.only(
                      right: index == provider.descriptionImageUrls.length - 1 ? 0 : 12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[800]),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _RatingSectionPlaceholder extends StatelessWidget {
  const _RatingSectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101C3B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.star, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Text(
            '4.8/5',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Phan danh gia se cap nhat khi co API',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterList extends StatelessWidget {
  const _ChapterList({
    required this.titles,
    required this.trailingIcon,
    required this.onTap,
  });

  final List<String> titles;
  final IconData trailingIcon;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (titles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Đang cập nhật chương...', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return ListView.builder(
      itemCount: titles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => onTap(index),
        leading: Text('${index + 1}'.padLeft(2, '0'), style: const TextStyle(color: Colors.white70)),
        title: Text(titles[index], style: const TextStyle(color: Colors.white)),
        trailing: Icon(trailingIcon, color: Colors.white54),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: (url == null || url!.isEmpty)
            ? Container(
                color: Colors.grey[800],
                child: const Icon(Icons.book, size: 50, color: Colors.grey),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[800]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.book, size: 50, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

