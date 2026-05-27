/// Liệt kê các mục đích sử dụng của mã xác thực OTP.
enum OtpPurpose {
  /// Xác minh địa chỉ email khi đăng ký tài khoản.
  verifyEmail('VERIFY_EMAIL'),

  /// Đặt lại mật khẩu bị quên.
  resetPassword('RESET_PASSWORD'),

  /// Thay đổi địa chỉ email liên kết với tài khoản.
  changeEmail('CHANGE_EMAIL');

  /// Khởi tạo một mục đích OTP với chuỗi giá trị tương ứng trên hệ thống Backend.
  const OtpPurpose(this.value);

  /// Chuỗi định danh mục đích OTP được sử dụng khi gửi dữ liệu lên API.
  final String value;

  /// Ánh xạ một chuỗi giá trị từ API thành đối tượng [OtpPurpose] tương ứng.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [value]: Chuỗi giá trị cần ánh xạ (ví dụ: 'VERIFY_EMAIL').
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [OtpPurpose]. Nếu không khớp, trả về giá trị mặc định [OtpPurpose.verifyEmail].
  static OtpPurpose fromValue(String value) {
    return OtpPurpose.values.firstWhere(
      (item) => item.value == value,
      orElse: () => OtpPurpose.verifyEmail,
    );
  }
}
