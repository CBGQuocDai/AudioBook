import 'package:flutter/material.dart';

import 'book_detail_main_content_view.dart';

class BookDetailPreviewView extends StatelessWidget {
  const BookDetailPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookDetailMainContentView(isPreview: true);
  }
}

