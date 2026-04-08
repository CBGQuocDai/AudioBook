import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mobile_client/src/util/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        ' pk_test_51TJwfQFmNKLpnSxIvNFuAYoO0fu82YG7Hrsh9T05ZIfA0kTjY166kuODtYEyS7zt6L2MkbuEIExPDY9mqeheoa9800mdqPXHjC',
  );

  if (publishableKey.isNotEmpty) {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Book App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
