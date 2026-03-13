import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/book_detail_provider.dart';
import 'component/body.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookDetailProvider(),
      child: const Scaffold(
        body: SafeArea(
          child: BookDetailBody(),
        ),
      ),
    );
  }
}