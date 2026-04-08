import 'package:flutter/material.dart';
import 'package:mobile_client/src/admin/home/screens/admin_main_screen.dart';
import 'package:mobile_client/src/auth/screens/forgot_password_screen.dart';
import 'package:mobile_client/src/auth/screens/login_screen.dart';
import 'package:mobile_client/src/auth/screens/recover_password_screen.dart';
import 'package:mobile_client/src/auth/screens/register_screen.dart';
import 'package:mobile_client/src/auth/screens/verify_otp_screen.dart';
import 'package:mobile_client/src/components/audioBook/audio_book_screen.dart';
import 'package:mobile_client/src/components/audioBook/model/audio_book_route_args.dart';
import 'package:mobile_client/src/components/book_detail/book_detail_screen.dart';
import 'package:mobile_client/src/components/book_detail/model/book_detail_route_args.dart';
import 'package:mobile_client/src/components/library/screens/library_screen.dart';
import 'package:mobile_client/src/components/reading/model/reading_route_args.dart';
import 'package:mobile_client/src/components/reading/reading_screen.dart';
import 'package:mobile_client/src/home/screens/discovery_screen.dart';
import 'package:mobile_client/src/home/screens/search_results_screen.dart';
import 'package:mobile_client/src/home/screens/trending_screen.dart';
import 'package:mobile_client/src/profile/screens/change_email_screen.dart';
import 'package:mobile_client/src/profile/screens/change_password_screen.dart';
import 'package:mobile_client/src/profile/screens/change_username_screen.dart';
import 'package:mobile_client/src/profile/screens/premium_plan_screen.dart';
import 'package:mobile_client/src/profile/screens/profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String recoverPassword = '/recover-password';
  static const String home = '/home';
  static const String discovery = '/discovery';
  static const String searchResults = '/search-results';
  static const String trending = '/trending';
  static const String library = '/library';
  static const String bookDetail = '/book-detail';
  static const String reading = '/reading';
  static const String audioBook = '/audio-book';
  // Keep legacy route name to avoid breaking stale callers after pull.
  static const String bookDetailPreview = '/book-detail-preview';
  static const String adminHome = '/admin-home';
  static const String profile = '/profile';
  static const String changeUsername = '/profile/change-username';
  static const String changeEmail = '/profile/change-email';
  static const String changePassword = '/profile/change-password';
  static const String premiumPlan = '/profile/premium-plan';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      verifyOtp: (context) => const VerifyOtpScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      recoverPassword: (context) => const RecoverPasswordScreen(),
      home: (context) => const DiscoveryScreen(),
      discovery: (context) => const DiscoveryScreen(),
      trending: (context) => const TrendingScreen(),
      library: (context) => const LibraryScreen(),
      adminHome: (context) => const AdminMainScreen(),
      profile: (context) => const ProfileScreen(),
      changeUsername: (context) => const ChangeUsernameScreen(),
      changeEmail: (context) => const ChangeEmailScreen(),
      changePassword: (context) => const ChangePasswordScreen(),
      premiumPlan: (context) => const PremiumPlanScreen(),
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
      case bookDetail:
      case bookDetailPreview:
        final args = BookDetailRouteArgs.fromRouteArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (context) => BookDetailScreen(
            bookId: args.bookId,
            isRead: args.isRead,
          ),
        );
      case reading:
        final args = ReadingRouteArgs.fromRouteArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (context) => ReadingScreen(args: args),
        );
      case audioBook:
        final args = AudioBookRouteArgs.fromRouteArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (context) => AudioBookScreen(args: args),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => routes[settings.name] != null
              ? routes[settings.name]!(context)
              : const LoginScreen(),
        );
    }
  }
}
