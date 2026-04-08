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
            _TopBar(bookId: bookId),
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
  const _TopBar({required this.bookId});

  final int bookId;

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
            _BookmarkButton(bookId: bookId),
          ],
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatefulWidget {
  const _BookmarkButton({required this.bookId});

  final int bookId;

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _animController;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTap(BuildContext context) async {
    await _animController.reverse();
    await _animController.forward();
    if (!context.mounted) return;
    await context.read<BookDetailProvider>().toggleFavourite(context, widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookDetailProvider>(
      builder: (_, provider, __) {
        final isFav = provider.isFavourite;
        final isLoading = provider.isFavouriteLoading;

        return ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            decoration: BoxDecoration(
              color: isFav
                  ? const Color(0xFFE91E63).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => _handleTap(context),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: Icon(
                        isFav ? Icons.bookmark : Icons.bookmark_border,
                        key: ValueKey(isFav),
                        color: isFav ? const Color(0xFFE91E63) : Colors.white,
                      ),
                    ),
                  ),
          ),
        );
      },
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
