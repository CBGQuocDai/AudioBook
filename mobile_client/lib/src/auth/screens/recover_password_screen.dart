import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/recover_password_args.dart';
import 'package:mobile_client/src/auth/models/reset_password_request.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
import 'package:mobile_client/src/util/routes.dart';

/// Màn hình đặt lại mật khẩu mới (Khôi phục mật khẩu).
///
/// Sau khi xác thực thành công mã OTP khôi phục mật khẩu, người dùng sử dụng màn hình này
/// để tạo mật khẩu mới dựa trên mã Token khôi phục được truyền tới.
class RecoverPasswordScreen extends StatefulWidget {
  /// Khởi tạo [RecoverPasswordScreen].
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authApiService = AuthApiService(baseUrl: _baseUrl);

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  /// Giải mã/Lấy các đối số khôi phục mật khẩu truyền tới màn hình từ [ModalRoute].
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [context]: Ngữ cảnh BuildContext hiện tại của Widget.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [RecoverPasswordArgs] nếu hợp lệ, ngược lại trả về `null`.
  RecoverPasswordArgs? _resolveArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RecoverPasswordArgs) {
      return args;
    }
    return null;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Gửi yêu cầu đặt lại mật khẩu mới lên server.
  ///
  /// Phương thức này thực hiện:
  /// 1. Kiểm tra khớp mật khẩu ở phía Client thông qua FormState.
  /// 2. Gửi yêu cầu cập nhật mật khẩu mới thông qua [AuthApiService.resetPassword] kèm theo token khôi phục.
  /// 3. Nếu thành công, hiển thị thông báo SnackBar và chuyển hướng về màn hình đăng nhập [AppRoutes.login].
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [args]: Chứa token khôi phục và email của tài khoản.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> _submit(RecoverPasswordArgs args) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _authApiService.resetPassword(
        token: args.token,
        request: ResetPasswordRequest(
          password: _passwordController.text.trim(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      final message = ErrorTranslator.translate(error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _resolveArgs(context);
    if (args == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF12141D),
        body: Center(
          child: TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
            child: const Text('Dữ liệu không hợp lệ. Quay lại đăng nhập'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12141D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF171C28), Color(0xFF252833)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Khôi phục mật khẩu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'MẬT KHẨU MỚI',
                      style: TextStyle(
                        color: Color(0xFF8D95A8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      autofocus: true,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tạo mật khẩu mới',
                        hintStyle: const TextStyle(color: Color(0xFF5E677B)),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFFFF8B1F),
                            size: 18,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Vui lòng nhập mật khẩu mới';
                        }
                        if (text.length < 6) {
                          return 'Mật khẩu tối thiểu 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'NHẬP LẠI MẬT KHẨU MỚI',
                      style: TextStyle(
                        color: Color(0xFF8D95A8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nhập lại mật khẩu mới',
                        hintStyle: const TextStyle(color: Color(0xFF5E677B)),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          }),
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFFFF8B1F),
                            size: 18,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Vui lòng nhập lại mật khẩu';
                        }
                        if (text != _passwordController.text.trim()) {
                          return 'Mật khẩu nhập lại không khớp';
                        }
                        return null;
                      },
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8B1F), Color(0xFFE52E71)],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _submit(args),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Đặt lại mật khẩu',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
