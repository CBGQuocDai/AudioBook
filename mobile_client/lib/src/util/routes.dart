import 'package:flutter/material.dart';
import 'package:mobile_client/src/admin/home/screens/admin_main_screen.dart';
import 'package:mobile_client/src/auth/screens/forgot_password_screen.dart';
import 'package:mobile_client/src/auth/screens/login_screen.dart';
import 'package:mobile_client/src/auth/screens/register_screen.dart';
import 'package:mobile_client/src/auth/screens/verify_otp_screen.dart';
import 'package:mobile_client/src/components/book_detail/book_detail_screen.dart';
import 'package:mobile_client/src/home/screens/discovery_screen.dart';
import 'package:mobile_client/src/home/screens/search_results_screen.dart';
import 'package:mobile_client/src/home/screens/trending_screen.dart';
import 'package:mobile_client/src/components/book_detail_preview/book_detail_preview_screen.dart';
import 'package:mobile_client/src/components/library/screens/library_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String discovery = '/discovery';
  static const String searchResults = '/search-results';
  static const String trending = '/trending';
  static const String bookDetail = '/book-detail';
  static const String bookDetailPreview = '/book-detail-preview';
  static const String library = '/library';
  static const String adminHome = '/admin-home';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      verifyOtp: (context) => const VerifyOtpScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      home: (context) => const DiscoveryScreen(),
      discovery: (context) => const DiscoveryScreen(),
      trending: (context) => const TrendingScreen(),
      bookDetail: (context) => const BookDetailScreen(),
      library: (context) => const LibraryScreen(),
      adminHome: (context) => const AdminMainScreen(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case searchResults:
        final keyword = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            keyword: keyword ?? '',
          ),
        );
      case bookDetailPreview:
        final bookId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (context) => BookDetailPreviewScreen(
            bookId: bookId,
 BookDetailPreviewScreen      default:
        return MaterialPageRoute(
          builder: (context) => routes[settings.name] != null
              ? routes[settings.name]!(context)
              : const LoginScreen(),
        );
    }
  }
}

class BookDetailPreviewScreen {
}
