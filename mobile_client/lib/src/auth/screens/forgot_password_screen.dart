import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/otp_purpose.dart';
import 'package:mobile_client/src/auth/models/otp_request.dart';
import 'package:mobile_client/src/auth/models/verify_otp_args.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
import 'package:mobile_client/src/util/routes.dart';

/// Màn hình yêu cầu khôi phục mật khẩu (Quên mật khẩu).
///
/// Cho phép người dùng nhập địa chỉ email để yêu cầu gửi mã OTP phục vụ cho việc đặt lại mật khẩu mới.
class ForgotPasswordScreen extends StatefulWidget {
  /// Khởi tạo [ForgotPasswordScreen].
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService(baseUrl: _baseUrl);
  bool _isLoading = false;

  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Gửi yêu cầu đặt lại mật khẩu bằng email đã nhập.
  ///
  /// Phương thức này thực hiện:
  /// 1. Kiểm tra tính hợp lệ của trường nhập liệu email.
  /// 2. Gửi yêu cầu lên backend qua [AuthApiService.forgotPassword].
  /// 3. Nếu thành công, điều hướng sang màn hình Xác thực OTP [AppRoutes.verifyOtp] với mục đích là [OtpPurpose.resetPassword].
  /// 4. Nếu thất bại, hiển thị SnackBar dịch thông báo lỗi.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> _submitForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    try {
      final response =
          await _authApiService.forgotPassword(OtpRequest(email: email));
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      Navigator.pushNamed(
        context,
        AppRoutes.verifyOtp,
        arguments: VerifyOtpArgs(
          email: email,
          otpPurpose: OtpPurpose.resetPassword,
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      final message = ErrorTranslator.translate(error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B162F), Color(0xFF1E102B)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 430),
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: IconButton(
                                  iconSize: 18,
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'KHÔI PHỤC MẬT KHẨU',
                                style: TextStyle(
                                  color: Color(0xFF8D95A8),
                                  letterSpacing: 1.3,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 80),
                          const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 40,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Đừng lo! Điều này có thể xảy ra. Vui lòng nhập email gắn với tài khoản của bạn.',
                            style: TextStyle(
                                color: Color(0xFFA8AEC1), height: 1.45),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'ĐỊA CHỈ EMAIL',
                            style: TextStyle(
                              color: Color(0xFF8D95A8),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Color(0xFF1B1B1F)),
                            cursorColor: const Color(0xFF1B1B1F),
                            decoration: InputDecoration(
                              hintText: 'nguyenvana@gmail.com',
                              hintStyle:
                                  const TextStyle(color: Color(0xFF7A8092)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!_emailRegex.hasMatch(email)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8B1F), Color(0xFFE52E71)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _submitForgotPassword,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Đặt lại mật khẩu',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
