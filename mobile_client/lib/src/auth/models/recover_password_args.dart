/// Lớp chứa các đối số cần thiết truyền sang màn hình Khôi phục mật khẩu.
class RecoverPasswordArgs {
  /// Token xác minh dùng để đặt lại mật khẩu mới.
  final String token;

  /// Địa chỉ email của tài khoản đang cần khôi phục mật khẩu.
  final String email;

  /// Khởi tạo [RecoverPasswordArgs].
  const RecoverPasswordArgs({
    required this.token,
    required this.email,
  });
}
