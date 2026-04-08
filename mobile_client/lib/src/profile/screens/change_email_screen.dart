import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/otp_purpose.dart';
import 'package:mobile_client/src/auth/models/verify_otp_args.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
import 'package:mobile_client/src/core/widgets/form_error_widget.dart';
import 'package:mobile_client/src/util/routes.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final _newEmailController = TextEditingController();
  final _authApiService = AuthApiService(baseUrl: _baseUrl);
  final _tokenStorageService = TokenStorageService();

  bool _isLoading = false;
  String _currentEmail = '';
  String? _emailError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _currentEmail.isEmpty) {
      _currentEmail = args;
    }
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    setState(() => _emailError = null);

    final newEmail = _newEmailController.text.trim();
    if (newEmail.isEmpty) {
      setState(() => _emailError = 'Email không được bỏ trống');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(newEmail)) {
      setState(() => _emailError = 'Email không hợp lệ');
      return;
    }

    final token = await _tokenStorageService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phiên đăng nhập đã hết hạn.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _authApiService.preChangeEmail(
        token: token,
        newEmail: newEmail,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.verifyOtp,
        arguments: VerifyOtpArgs(
          email: newEmail,
          otpPurpose: OtpPurpose.changeEmail,
        ),
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      final translated = ErrorTranslator.translate(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translated),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22242D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22242D),
        title: const Text('Đổi email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'EMAIL HIỆN TẠI',
                style: TextStyle(color: Color(0xFF8D95A8), fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(
                  text: _currentEmail.isEmpty ? '-' : _currentEmail,
                ),
                enabled: false,
                decoration: InputDecoration(
                  suffixIcon: const Icon(Icons.lock_outline, size: 16),
                  filled: true,
                  fillColor: const Color(0xFF1D2331),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'EMAIL MỚI',
                style: TextStyle(color: Color(0xFF8D95A8), fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newEmailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Nhập email mới',
                  filled: true,
                  fillColor: const Color(0xFF1D2331),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: _emailError != null
                        ? const BorderSide(
                            color: Color(0xFFEF4444), width: 1.5)
                        : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: _emailError != null
                        ? const BorderSide(
                            color: Color(0xFFEF4444), width: 1.5)
                        : BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),
              if (_emailError != null) FormErrorWidget(error: _emailError),
              const SizedBox(height: 10),
              const Text(
                'OTP xác thực sẽ được gửi đến email mới.',
                style: TextStyle(color: Color(0xFF7C8292), fontSize: 11),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8B1F), Color(0xFFE96A15)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                          'Xác thực email',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
