/// Lớp chứa dữ liệu yêu cầu đổi mật khẩu của người dùng.
class ChangePasswordRequest {
  /// Mật khẩu hiện tại của tài khoản.
  final String oldPassword;

  /// Mật khẩu mới muốn thay đổi.
  final String newPassword;

  /// Khởi tạo [ChangePasswordRequest] với mật khẩu cũ và mới.
  const ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  /// Chuyển đổi dữ liệu đối tượng thành bản đồ JSON để gửi qua HTTP Request.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Map<String, dynamic>] chứa các thông tin yêu cầu đổi mật khẩu.
  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}
