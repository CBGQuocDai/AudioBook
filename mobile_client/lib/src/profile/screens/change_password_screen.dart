import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/change_password_request.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
import 'package:mobile_client/src/core/widgets/form_error_widget.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authApiService = AuthApiService(baseUrl: _baseUrl);
  final _tokenStorageService = TokenStorageService();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _currentError = '';
  String _newError = '';
  String _confirmError = '';

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    setState(() {
      _currentError = '';
      _newError = '';
      _confirmError = '';
    });

    final current = _currentController.text.trim();
    final newPassword = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    bool isValid = true;

    if (current.isEmpty) {
      setState(() => _currentError = 'Vui lòng nhập mật khẩu hiện tại');
      isValid = false;
    }

    if (newPassword.isEmpty) {
      setState(() => _newError = 'Vui lòng nhập mật khẩu mới');
      isValid = false;
    } else if (newPassword.length < 6) {
      setState(() => _newError = 'Mật khẩu tối thiểu 6 ký tự');
      isValid = false;
    }

    if (confirm.isEmpty) {
      setState(() => _confirmError = 'Vui lòng nhập lại mật khẩu');
      isValid = false;
    } else if (confirm != newPassword) {
      setState(() => _confirmError = 'Mật khẩu nhập lại không khớp');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _submit() async {
    if (!_validateFields()) return;

    setState(() => _isLoading = true);
    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const AuthApiException('Phiên đăng nhập đã hết hạn.');
      }

      final response = await _authApiService.changePassword(
        token: token,
        request: ChangePasswordRequest(
          oldPassword: _currentController.text.trim(),
          newPassword: _newController.text.trim(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      Navigator.pop(context);
    } on AuthApiException catch (e) {
      if (!mounted) return;
      final message = ErrorTranslator.translate(e.message);
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
    return Scaffold(
      backgroundColor: const Color(0xFF22242D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22242D),
        title: const Text('Đổi mật khẩu'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hãy dùng mật khẩu mạnh và riêng biệt để bảo vệ tài khoản của bạn.',
                style: TextStyle(color: Color(0xFFA7AFC3), height: 1.4),
              ),
              const SizedBox(height: 18),
              const Text(
                'MẬT KHẨU HIỆN TẠI',
                style: TextStyle(color: Color(0xFF8D95A8), fontSize: 11),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _currentController,
                hint: 'Nhập mật khẩu hiện tại',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                error: _currentError,
              ),
              if (_currentError.isNotEmpty) ...[
                const SizedBox(height: 6),
                FormErrorWidget(error: _currentError),
              ],
              const SizedBox(height: 14),
              const Text(
                'MẬT KHẨU MỚI',
                style: TextStyle(color: Color(0xFF8D95A8), fontSize: 11),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _newController,
                hint: 'Tạo mật khẩu mới',
                autofocus: true,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                error: _newError,
              ),
              if (_newError.isNotEmpty) ...[
                const SizedBox(height: 6),
                FormErrorWidget(error: _newError),
              ],
              const SizedBox(height: 14),
              const Text(
                'NHẬP LẠI MẬT KHẨU MỚI',
                style: TextStyle(color: Color(0xFF8D95A8), fontSize: 11),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmController,
                hint: 'Nhập lại mật khẩu mới',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                error: _confirmError,
              ),
              if (_confirmError.isNotEmpty) ...[
                const SizedBox(height: 6),
                FormErrorWidget(error: _confirmError),
              ],
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8B1F), Color(0xFFE96A15)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
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
                          'Cập nhật mật khẩu',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String error,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF1D2331),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            size: 18,
            color: const Color(0xFFFF8B1F),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: error.isNotEmpty
              ? const BorderSide(color: Color(0xFFFF4444), width: 1)
              : BorderSide.none,
        ),
      ),
    );
  }
}
