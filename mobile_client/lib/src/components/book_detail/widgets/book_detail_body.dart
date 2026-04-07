import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/book_detail_provider.dart';

class BookDetailBody extends StatelessWidget {
  const BookDetailBody({
    super.key,
    required this.bookId,
  });

  final int bookId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookDetailProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Book #$bookId'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Book detail screen'),
            const SizedBox(height: 12),
            Text('Current tab: ${provider.currentTab}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => provider.changeTab(0),
                  child: const Text('About'),
                ),
                ElevatedButton(
                  onPressed: () => provider.changeTab(1),
                  child: const Text('Chapter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

