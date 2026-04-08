/// Utility class to translate backend error messages to Vietnamese
class ErrorTranslator {
  static const Map<String, String> _translations = {
    // User/Auth errors
    'user not found': 'Người dùng không tồn tại',
    'invalid email or password': 'Email hoặc mật khẩu không đúng',
    'invalid credentials': 'Thông tin đăng nhập không hợp lệ',
    'email already exists': 'Email này đã được đăng ký',
    'email already in use': 'Email này đã được sử dụng',
    'email is already taken': 'Email này đã được đăng ký',
    'account not activated': 'Tài khoản chưa được kích hoạt',
    'account is locked': 'Tài khoản bị khóa',
    'account has been deleted': 'Tài khoản đã bị xóa',
    'session expired': 'Phiên đăng nhập đã hết hạn',
    'unauthorized': 'Không có quyền truy cập',
    'forbidden': 'Bạn không có quyền thực hiện hành động này',

    // Validation errors
    'invalid email': 'Email không hợp lệ',
    'invalid phone': 'Số điện thoại không hợp lệ',
    'password too short': 'Mật khẩu quá ngắn',
    'password must be at least': 'Mật khẩu phải có ít nhất',
    'password confirmation does not match': 'Mật khẩu không khớp',
    'passwords do not match': 'Mật khẩu không khớp',
    'invalid username': 'Tên người dùng không hợp lệ',
    'username already exists': 'Tên người dùng này đã được sử dụng',
    'name is required': 'Tên không được bỏ trống',
    'email is required': 'Email không được bỏ trống',
    'password is required': 'Mật khẩu không được bỏ trống',

    // OTP errors
    'invalid otp': 'Mã OTP không hợp lệ',
    'otp expired': 'Mã OTP đã hết hạn',
    'otp not found': 'Mã OTP không tìm thấy',
    'maximum otp attempts exceeded': 'Bạn đã vượt quá số lần thử OTP tối đa',
    'otp rate limit exceeded': 'Quá nhiều yêu cầu OTP, vui lòng thử lại sau',

    // Email verification
    'email verification failed': 'Xác minh email thất bại',
    'email not verified': 'Email chưa được xác minh',
    'email verification link expired': 'Liên kết xác minh email đã hết hạn',

    // Password reset
    'reset password link expired': 'Liên kết đặt lại mật khẩu đã hết hạn',
    'invalid reset token': 'Token đặt lại mật khẩu không hợp lệ',
    'current password is incorrect': 'Mật khẩu hiện tại không đúng',
    'new password cannot be the same as old password': 'Mật khẩu mới không được giống mật khẩu cũ',

    // API/Network errors
    'connection timeout': 'Kết nối bị timeout, vui lòng thử lại',
    'request timeout': 'Yêu cầu bị timeout, vui lòng thử lại',
    'network error': 'Lỗi mạng, vui lòng kiểm tra kết nối internet',
    'server error': 'Lỗi máy chủ, vui lòng thử lại sau',
    'bad request': 'Yêu cầu không hợp lệ',
    'not found': 'Không tìm thấy',
    'internal server error': 'Lỗi máy chủ nội bộ',

    // Payment/Subscription errors
    'payment failed': 'Thanh toán thất bại',
    'subscription not found': 'Gói hội viên không tìm thấy',
    'subscription already active': 'Gói hội viên đã được kích hoạt',
    'invalid payment method': 'Phương thức thanh toán không hợp lệ',

    // Credit errors
    'insufficient credit': 'Không đủ credit',
    'invalid credit amount': 'Số lượng credit không hợp lệ',
    'credit plan not found': 'Gói credit không tìm thấy',

    // File/Avatar errors
    'file too large': 'Tệp quá lớn',
    'invalid file type': 'Loại tệp không hợp lệ',
    'file upload failed': 'Tải lên tệp thất bại',
    'avatar update failed': 'Cập nhật ảnh đại diện thất bại',
  };

  /// Translate backend error message to Vietnamese
  static String translate(String message) {
    if (message.isEmpty) {
      return 'Có lỗi xảy ra, vui lòng thử lại';
    }

    final lower = message.toLowerCase().trim();

    // Direct match
    if (_translations.containsKey(lower)) {
      return _translations[lower]!;
    }

    // Partial match (check if any key is contained in the message)
    for (final entry in _translations.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // If no match found, return original message
    return message;
  }
}
