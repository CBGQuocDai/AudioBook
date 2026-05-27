import 'package:mobile_client/src/auth/models/otp_purpose.dart';

/// Lớp chứa thông tin để gửi yêu cầu xác thực mã OTP lên máy chủ.
class VerifyOtpRequest {
  /// Mã OTP gồm các chữ số do người dùng nhập vào.
  final String otp;

  /// Địa chỉ email tương ứng nhận mã OTP.
  final String email;

  /// Mục đích xác minh của mã OTP này.
  final OtpPurpose otpPurpose;

  /// Khởi tạo [VerifyOtpRequest].
  const VerifyOtpRequest({
    required this.otp,
    required this.email,
    required this.otpPurpose,
  });

  /// Chuyển đổi dữ liệu đối tượng thành bản đồ JSON để gửi qua HTTP Request.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Map<String, dynamic>] chứa các thông tin xác thực OTP.
  Map<String, dynamic> toJson() {
    return {
      'otp': otp,
      'email': email,
      'otpPurpose': otpPurpose.value,
    };
  }
}
