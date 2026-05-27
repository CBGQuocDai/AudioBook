import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mobile_client/src/util/routes.dart';

/// Điểm khởi đầu (Entrypoint) của ứng dụng di động AudioBook.
///
/// Phương thức này thực hiện các bước khởi tạo ứng dụng:
/// 1. Đảm bảo các dịch vụ Flutter binding được khởi tạo đầy đủ.
/// 2. Cấu hình khóa Stripe Publishable Key từ môi trường hoặc sử dụng khóa mặc định để xử lý thanh toán.
/// 3. Khởi chạy widget chính của ứng dụng [MyApp].
///
/// * **Tham số đầu vào (Input):**
///   - Không có.
/// * **Kết quả đầu ra (Output):**
///   - Trả về [Future<void>].
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

/// Widget gốc của ứng dụng (Root Widget).
///
/// Quản lý cấu hình chủ đề (Theme), định tuyến (Routing) và hiển thị màn hình khởi đầu của ứng dụng.
class MyApp extends StatelessWidget {
  /// Khởi tạo [MyApp].
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
