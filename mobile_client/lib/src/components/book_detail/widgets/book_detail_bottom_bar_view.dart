import 'package:flutter/material.dart';
import 'package:mobile_client/src/components/book_detail/provider/book_detail_provider.dart';
import 'package:provider/provider.dart';

class BookDetailBottomBarView extends StatelessWidget {
  const BookDetailBottomBarView({
    super.key,
    required this.bookId,
  });

  final int bookId;

  @override
  Widget build(BuildContext context) {
    return Consumer<BookDetailProvider>(
      builder: (context, provider, child) {
        final isPurchasing = provider.isPurchasing;
        
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: ElevatedButton.icon(
            onPressed: isPurchasing ? null : () {
              print('[BookDetailBottomBarView] Bấm nút mua ngay');
              provider.purchaseBook(context);
            },
            icon: isPurchasing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              isPurchasing ? 'Đang xử lý...' : 'Mua ngay',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPurchasing ? Colors.orange.withValues(alpha: 0.5) : Colors.orange,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        );
      },
    );
  }
}

