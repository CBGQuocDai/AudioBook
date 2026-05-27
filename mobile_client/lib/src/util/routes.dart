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

/// Lớp quản lý toàn bộ các tuyến đường (Routing) trong ứng dụng.
///
/// Định nghĩa tất cả các hằng số tên đường dẫn (Route names) và hàm xử lý định tuyến.
class AppRoutes {
  /// Đường dẫn màn hình đăng nhập.
  static const String login = '/login';
  /// Đường dẫn màn hình đăng ký tài khoản.
  static const String register = '/register';
  /// Đường dẫn màn hình xác thực mã OTP.
  static const String verifyOtp = '/verify-otp';
  /// Đường dẫn màn hình yêu cầu đặt lại mật khẩu.
  static const String forgotPassword = '/forgot-password';
  /// Đường dẫn màn hình khôi phục/đặt mật khẩu mới.
  static const String recoverPassword = '/recover-password';
  /// Đường dẫn màn hình khám phá sách nói.
  static const String discovery = '/discovery';
  /// Đường dẫn màn hình chính (alias cho màn hình khám phá).
  static const String home = discovery;
  /// Đường dẫn màn hình thông tin cá nhân.
  static const String profile = '/profile';
  /// Đường dẫn màn hình thay đổi tên hiển thị.
  static const String changeUsername = '/profile/change-username';
  /// Đường dẫn màn hình thay đổi email.
  static const String changeEmail = '/profile/change-email';
  /// Đường dẫn màn hình thay đổi mật khẩu.
  static const String changePassword = '/profile/change-password';
  /// Đường dẫn màn hình mua gói Premium.
  static const String premiumPlan = '/profile/premium-plan';
  /// Đường dẫn màn hình quản lý thông tin đăng ký gói.
  static const String subscription = '/profile/subscription';
  /// Đường dẫn màn hình nạp xu/tín dụng.
  static const String buyCredit = '/payment/buy-credit';

  /// Danh sách ánh xạ giữa tên đường dẫn và hàm dựng Widget tương ứng.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Map<String, WidgetBuilder>] chứa danh sách các màn hình tĩnh.
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

  /// Trình tạo tuyến đường động (Dynamic Route Generator).
  ///
  /// Được gọi bởi Flutter Navigator khi sử dụng [Navigator.pushNamed].
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [settings]: Chứa thông tin cấu hình tuyến đường bao gồm cả tên màn hình cần chuyển tới.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Route<dynamic>] chỉ định đối tượng Route sẽ được đẩy vào stack.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => routes[settings.name] != null
          ? routes[settings.name]!(context)
          : const LoginScreen(),
    );
  }
}
