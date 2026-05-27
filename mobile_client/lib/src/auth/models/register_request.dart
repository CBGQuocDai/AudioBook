/// Lớp chứa thông tin cần thiết để gửi yêu cầu đăng ký tài khoản mới.
class RegisterRequest {
  /// Tên hiển thị của người dùng.
  final String name;

  /// Địa chỉ email đăng ký tài khoản.
  final String email;

  /// Mật khẩu muốn thiết lập.
  final String password;

  /// Khởi tạo [RegisterRequest] với tên, email và mật khẩu.
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  /// Chuyển đổi dữ liệu đối tượng thành bản đồ JSON để gửi qua HTTP Request.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Map<String, dynamic>] chứa các thông tin đăng ký.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
    };
  }
}