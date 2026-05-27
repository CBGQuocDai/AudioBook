import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/reading_route_args.dart';
import 'provider/reading_provider.dart';
import 'widgets/reading_body.dart';

/// Màn hình đọc sách điện tử (Ebook).
/// Hỗ trợ đọc nội dung phân trang, chuyển chương, chuyển trang và đồng bộ tiến trình đọc.
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({
    super.key,
    required this.args,
  });

  final ReadingRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReadingProvider()..initialize(args),
      child: const ReadingBody(),
    );
  }
}

