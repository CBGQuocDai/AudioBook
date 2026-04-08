import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/otp_purpose.dart';
import 'package:mobile_client/src/auth/models/register_request.dart';
import 'package:mobile_client/src/auth/models/verify_otp_args.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
import 'package:mobile_client/src/util/routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthApiService _authApiService = AuthApiService(baseUrl: _baseUrl);
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreed = false;

  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');

  int get _passwordStrength {
    final value = _passwordController.text.trim();
    if (value.length >= 10) return 3;
    if (value.length >= 8) return 2;
    if (value.length >= 6) return 1;
    return 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng đồng ý điều khoản trước khi đăng ký')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    try {
      final response = await _authApiService.register(
        RegisterRequest(
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
        ),
      );
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
          otpPurpose: OtpPurpose.verifyEmail,
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      final translated = ErrorTranslator.translate(error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translated), backgroundColor: Colors.redAccent),
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
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A132C), Color(0xFF1A1328)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Tạo tài khoản mới',
                        style: TextStyle(color: Color(0xFFB3BACD)),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF8B1F), Color(0xFFE52E71)],
                            ),
                          ),
                          child: const Icon(Icons.app_registration_rounded,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tạo tài khoản',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bắt đầu hành trình đọc sách của bạn ngay hôm nay.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFAAB0C3)),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Họ và tên',
                          labelStyle: const TextStyle(color: Color(0xFF8D95A8)),
                          hintText: 'Nguyễn Văn A',
                          hintStyle: const TextStyle(color: Color(0xFF7D8599)),
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Color(0xFF7D8599), size: 18),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Vui lòng nhập họ tên';
                          }
                          if (text.length < 2) {
                            return 'Họ tên phải có ít nhất 2 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ email',
                          labelStyle: const TextStyle(color: Color(0xFF8D95A8)),
                          hintText: 'john@example.com',
                          hintStyle: const TextStyle(color: Color(0xFF7D8599)),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Color(0xFF7D8599), size: 18),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          labelStyle: const TextStyle(color: Color(0xFF8D95A8)),
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: Color(0xFF7D8599)),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Color(0xFF7D8599), size: 18),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF7D8599),
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          final password = value?.trim() ?? '';
                          if (password.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (password.length < 6) {
                            return 'Mật khẩu tối thiểu 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(
                          3,
                          (index) => Expanded(
                            child: Container(
                              margin:
                                  EdgeInsets.only(right: index == 2 ? 0 : 6),
                              height: 3,
                              decoration: BoxDecoration(
                                color: index < _passwordStrength
                                    ? const Color(0xFF5FA4FF)
                                    : const Color(0xFF3A4153),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nhập lại mật khẩu',
                          labelStyle: const TextStyle(color: Color(0xFF8D95A8)),
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: Color(0xFF7D8599)),
                          prefixIcon: const Icon(Icons.lock_reset,
                              color: Color(0xFF7D8599), size: 18),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            }),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF7D8599),
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Vui lòng nhập lại mật khẩu';
                          }
                          if (text != _passwordController.text.trim()) {
                            return 'Mật khẩu xác nhận không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _agreed,
                              activeColor: const Color(0xFFFF8B1F),
                              onChanged: (value) {
                                setState(() => _agreed = value ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Tôi đồng ý với ',
                                    style: TextStyle(color: Color(0xFFAAB0C3)),
                                  ),
                                  TextSpan(
                                    text: 'Điều khoản dịch vụ',
                                    style: TextStyle(
                                      color: Color(0xFFFFA83A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' và ',
                                    style: TextStyle(color: Color(0xFFAAB0C3)),
                                  ),
                                  TextSpan(
                                    text: 'Chính sách quyền riêng tư',
                                    style: TextStyle(
                                      color: Color(0xFFFFA83A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8B1F), Color(0xFFE52E71)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                                  'Tạo tài khoản  →',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.white.withValues(alpha: 0.1))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'HOẶC TIẾP TỤC VỚI',
                              style: TextStyle(
                                  color: Color(0xFF7E869A), fontSize: 10),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.white.withValues(alpha: 0.1))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Text('G',
                            style: TextStyle(
                                color: Color(0xFFEA4335),
                                fontWeight: FontWeight.w700)),
                        label: const Text('Google'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Đã có tài khoản? ',
                              style: TextStyle(color: Color(0xFFAAB0C3))),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                  color: Color(0xFFFFAA3B),
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
