/// Lớp chứa thông tin cần thiết để gửi yêu cầu đăng nhập tài khoản.
class LoginRequest {
  /// Địa chỉ email đăng nhập.
  final String email;

  /// Mật khẩu đăng nhập.
  final String password;

  /// Khởi tạo [LoginRequest] với email và mật khẩu.
  const LoginRequest({
    required this.email,
    required this.password,
  });

  /// Chuyển đổi dữ liệu đối tượng thành bản đồ JSON để gửi qua HTTP Request.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Map<String, dynamic>] chứa thông tin email và mật khẩu của người dùng.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
