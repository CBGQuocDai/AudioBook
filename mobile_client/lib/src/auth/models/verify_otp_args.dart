import 'package:mobile_client/src/auth/models/otp_purpose.dart';

/// Lớp chứa các thông số cần thiết truyền vào màn hình Xác minh mã OTP.
class VerifyOtpArgs {
  /// Địa chỉ email cần thực hiện xác minh mã OTP.
  final String email;

  /// Mục đích của việc xác minh mã OTP này (ví dụ: đăng ký tài khoản mới, khôi phục mật khẩu).
  final OtpPurpose otpPurpose;

  /// Khởi tạo đối tượng [VerifyOtpArgs].
  const VerifyOtpArgs({
    required this.email,
    required this.otpPurpose,
  });
}
