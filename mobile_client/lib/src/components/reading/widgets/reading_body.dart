import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:mobile_client/src/components/book_detail/model/book_detail_route_args.dart';
import 'package:mobile_client/src/util/routes.dart';
import 'package:provider/provider.dart';

import '../provider/reading_provider.dart';

class ReadingBody extends StatelessWidget {
  const ReadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final chapter = provider.currentChapter;
    final showLockedOverlay =
        provider.isLockedMode && (provider.progress > 0.5 || provider.forceLockedPrompt);

    return PopScope(
      onPopInvoked: (didPop) {
        print('[ReadingBody] onPopInvoked: didPop=$didPop');
        if (didPop) {
          provider.syncProgress();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF120B04),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(title: chapter?.title ?? 'READING'),
              Expanded(
                child: Stack(
                  children: [
                    _ReadingContent(provider: provider),
                    if (showLockedOverlay) _LockedOverlay(bookId: provider.bookId),
                  ],
                ),
              ),
              _BottomPanel(provider: provider),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedOverlay extends StatelessWidget {
  const _LockedOverlay({required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1208),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'Mua để mở khoá phần tiếp theo',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.bookDetail,
                      arguments: BookDetailRouteArgs(bookId: bookId, isRead: 1),
                    );
                  },
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  label: const Text(
                    'Mua ngay',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ReadingContent extends StatelessWidget {
  const _ReadingContent({required this.provider});

  final ReadingProvider provider;

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final filePath = provider.localPdfPath;
    if (filePath == null || filePath.isEmpty) {
      return const Center(
        child: Text('Đang chuẩn bị nội dung...', style: TextStyle(color: Colors.white70)),
      );
    }

    return PDFView(
      key: ValueKey(filePath),
      filePath: filePath,
      defaultPage: provider.initialPage,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      backgroundColor: const Color(0xFF120B04),
      onRender: provider.onRender,
      onViewCreated: provider.onViewCreated,
      onPageChanged: provider.onPageChanged,
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      },
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.provider});

  final ReadingProvider provider;

  @override
  Widget build(BuildContext context) {
    final percent = (provider.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final pageText = provider.totalPages > 0
        ? 'Page ${provider.currentPage + 1} of ${provider.totalPages}'
        : 'Page 0 of 0';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percent% đã đọc', style: const TextStyle(color: Colors.white54)),
              Text(pageText, style: const TextStyle(color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: provider.progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundButton(
                icon: Icons.menu,
                label: 'CHƯƠNG',
                onTap: () => _showChapterSheet(context, provider),
              ),
              _RoundButton(
                icon: Icons.chevron_left,
                label: 'Trước',
                onTap: provider.prevPage,
              ),
              _RoundButton(
                icon: Icons.chevron_right,
                label: 'Sau',
                onTap: provider.nextPage,
              ),
              _RoundButton(
                icon: provider.isFavourite ? Icons.bookmark : Icons.bookmark_border,
                label: 'YÊU THÍCH',
                onTap: () => provider.toggleFavourite(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showChapterSheet(BuildContext context, ReadingProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.25,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1C1208),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Danh sách chương',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: provider.chapters.length,
                      itemBuilder: (_, index) {
                        final chapter = provider.chapters[index];
                        final selected = index == provider.chapterIndex;
                        final canOpen = provider.canOpenChapter(index);

                        return ListTile(
                          onTap: canOpen
                              ? () async {
                                  provider.clearLockedPrompt();
                                  Navigator.pop(sheetContext);
                                  await provider.goToChapter(index);
                                }
                              : () {
                                  Navigator.pop(sheetContext);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    provider.showLockedPrompt();
                                  });
                                },
                          leading: CircleAvatar(
                            backgroundColor: selected
                                ? Colors.orange
                                : (canOpen ? const Color(0xFF2B1B07) : const Color(0xFF3A3A3A)),
                            child: Text(
                              '${chapter.chapterNumber}',
                              style: TextStyle(color: selected ? Colors.black : Colors.white),
                            ),
                          ),
                          title: Text(
                            chapter.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? Colors.orange
                                  : (canOpen ? Colors.white : Colors.white54),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: !canOpen
                              ? const Icon(Icons.lock_outline, color: Colors.orange)
                              : (selected
                                  ? const Icon(Icons.play_arrow, color: Colors.orange)
                                  : const Icon(Icons.chevron_right, color: Colors.white54)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2B1B07),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}







