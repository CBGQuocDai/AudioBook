/// Lớp chứa thông tin email dùng để gửi yêu cầu sinh và gửi mã OTP mới.
class OtpRequest {
  /// Địa chỉ email muốn nhận mã OTP.
  final String email;

  /// Khởi tạo [OtpRequest] với email đã chỉ định.
  const OtpRequest({required this.email});

  /// Chuyển đổi dữ liệu đối tượng thành bản đồ JSON để gửi qua HTTP Request.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Map<String, dynamic>] chứa email.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
