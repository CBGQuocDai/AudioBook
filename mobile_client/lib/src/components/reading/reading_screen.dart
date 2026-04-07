import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/reading_route_args.dart';
import 'provider/reading_provider.dart';
import 'widgets/reading_body.dart';

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

