/// Lớp chứa thông tin mật khẩu mới dùng để đặt lại mật khẩu sau khi xác minh OTP thành công.
class ResetPasswordRequest {
  /// Mật khẩu mới mong muốn thiết lập.
  final String password;

  /// Khởi tạo [ResetPasswordRequest] với mật khẩu mới.
  const ResetPasswordRequest({required this.password});

  /// Chuyển đổi dữ liệu đối tượng thành bản đồ JSON để gửi qua HTTP Request.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Map<String, dynamic>] chứa mật khẩu.
  Map<String, dynamic> toJson() {
    return {
      'password': password,
    };
  }
}
