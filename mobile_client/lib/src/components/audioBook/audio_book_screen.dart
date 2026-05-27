import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/audio_book_route_args.dart';
import 'provider/audio_book_provider.dart';
import 'widgets/audio_book_body.dart';

/// Màn hình phát sách nói (AudioBook).
/// Cho phép người dùng nghe sách, điều chỉnh tốc độ, chuyển chương, hẹn giờ và đồng bộ tiến trình nghe.
class AudioBookScreen extends StatelessWidget {
  const AudioBookScreen({
    super.key,
    required this.args,
  });

  final AudioBookRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioBookProvider()..initialize(args),
      child: const AudioBookBody(),
    );
  }
}

