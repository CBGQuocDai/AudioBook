import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/book_detail_provider.dart';
import 'widgets/book_detail_body.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({
    super.key,
    this.bookId = 0,
  });

  final int bookId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookDetailProvider(),
      child: BookDetailBody(bookId: bookId),
    );
  }
}