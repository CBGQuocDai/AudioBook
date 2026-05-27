import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/screens/forgot_password_screen.dart';
import 'package:mobile_client/src/auth/screens/login_screen.dart';
import 'package:mobile_client/src/auth/screens/recover_password_screen.dart';
import 'package:mobile_client/src/auth/screens/register_screen.dart';
import 'package:mobile_client/src/auth/screens/verify_otp_screen.dart';
import 'package:mobile_client/src/home/screens/discovery_screen.dart';
import 'package:mobile_client/src/payment/screens/buy_credit_screen.dart';
import 'package:mobile_client/src/profile/screens/change_email_screen.dart';
import 'package:mobile_client/src/profile/screens/change_password_screen.dart';
import 'package:mobile_client/src/profile/screens/change_username_screen.dart';
import 'package:mobile_client/src/profile/screens/premium_plan_screen.dart';
import 'package:mobile_client/src/profile/screens/profile_screen.dart';
import 'package:mobile_client/src/profile/screens/subscription_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String recoverPassword = '/recover-password';
  static const String discovery = '/discovery';
  static const String home = discovery;
  static const String profile = '/profile';
  static const String changeUsername = '/profile/change-username';
  static const String changeEmail = '/profile/change-email';
  static const String changePassword = '/profile/change-password';
  static const String premiumPlan = '/profile/premium-plan';
  static const String subscription = '/profile/subscription';
  static const String buyCredit = '/payment/buy-credit';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      verifyOtp: (context) => const VerifyOtpScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      recoverPassword: (context) => const RecoverPasswordScreen(),
      discovery: (context) => const DiscoveryScreen(),
      profile: (context) => const ProfileScreen(),
      changeUsername: (context) => const ChangeUsernameScreen(),
      changeEmail: (context) => const ChangeEmailScreen(),
      changePassword: (context) => const ChangePasswordScreen(),
      premiumPlan: (context) => const PremiumPlanScreen(),
      subscription: (context) => const SubscriptionScreen(),
      buyCredit: (context) => const BuyCreditScreen(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => routes[settings.name] != null
          ? routes[settings.name]!(context)
          : const LoginScreen(),
    );
  }
}
