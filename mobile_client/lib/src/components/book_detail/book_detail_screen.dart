import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/book_detail_provider.dart';
import 'widgets/book_detail_body.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.isRead,
  });

  final int bookId;
  final int? isRead;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookDetailProvider(
        forceReadMode: isRead == 1,
      )..fetchBookDetails(bookId),
      child: BookDetailBody(bookId: bookId),
    );
  }
}