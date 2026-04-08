import 'package:flutter/material.dart';
import 'package:mobile_client/src/components/book_detail/model/book_detail_route_args.dart';
import 'package:mobile_client/src/util/routes.dart';

class BookDetailBottomBarView extends StatelessWidget {
  const BookDetailBottomBarView({
    super.key,
    required this.bookId,
  });

  final int bookId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
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
          'Mở khoá',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}

