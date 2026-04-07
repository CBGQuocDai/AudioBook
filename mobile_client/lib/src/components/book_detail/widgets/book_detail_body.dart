import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/book_detail_provider.dart';
import 'book_detail_bottom_bar_view.dart';
import 'book_detail_full_view.dart';
import 'book_detail_preview_view.dart';

class BookDetailBody extends StatelessWidget {
  const BookDetailBody({
    super.key,
    required this.bookId,
  });

  final int bookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      body: SafeArea(
        child: Stack(
          children: [
            Consumer<BookDetailProvider>(
              builder: (_, provider, __) {
                if (provider.isReadMode) {
                  return const BookDetailFullView();
                }
                return const BookDetailPreviewView();
              },
            ),
            const _TopBar(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Consumer<BookDetailProvider>(
                builder: (_, provider, __) {
                  if (provider.isReadMode) {
                    return const SizedBox.shrink();
                  }
                  return BookDetailBottomBarView(bookId: bookId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            const _CircleIconButton(
              icon: Icons.bookmark_border,
              onTap: _noop,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

void _noop() {}

