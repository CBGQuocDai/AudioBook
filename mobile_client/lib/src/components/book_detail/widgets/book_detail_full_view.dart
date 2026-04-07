import 'package:flutter/material.dart';

import 'book_detail_main_content_view.dart';

class BookDetailFullView extends StatelessWidget {
  const BookDetailFullView({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookDetailMainContentView(isPreview: false);
  }
}

