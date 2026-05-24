import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/login_request.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/google_auth_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
import 'package:mobile_client/src/core/widgets/form_error_widget.dart';
import 'package:mobile_client/src/util/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApiService = AuthApiService(baseUrl: _baseUrl);
  final _tokenStorageService = TokenStorageService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;

  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate email
    if (email.isEmpty) {
      setState(() => _emailError = 'Email không được bỏ trống');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Email không hợp lệ');
      return;
    }

    // Validate password
    if (password.isEmpty) {
      setState(() => _passwordError = 'Mật khẩu không được bỏ trống');
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordError = 'Mật khẩu tối thiểu 6 ký tự');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authApiService.login(
        LoginRequest(email: email, password: password),
      );

      final token = response.data?.token ?? '';
      if (token.isEmpty) {
        throw const AuthApiException('Không nhận được token từ server.');
      }

      final userInfo = response.data?.userInfo;
      await _tokenStorageService.saveAuthSession(
        token: token,
        userId: userInfo?.id,
        email: userInfo?.email,
        role: userInfo?.role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      final role = (userInfo?.role ?? 'USER').toUpperCase();
      Navigator.pushNamedAndRemoveUntil(
        context,
        role == 'ADMIN' ? AppRoutes.adminHome : AppRoutes.home,
        (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      final translated = ErrorTranslator.translate(error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translated), backgroundColor: Colors.redAccent),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      print('[DEBUG] Starting Google Sign-In...');
      final account = await GoogleAuthService.signIn();
      print('[DEBUG] Google Sign-In returned account: ${account?.email}');
      
      if (account == null) {
        throw const AuthApiException('Google Sign-In bị hủy');
      }

      print('[DEBUG] Getting ID Token...');
      final idToken = await GoogleAuthService.getIdToken();
      print('[DEBUG] ID Token length: ${idToken?.length ?? 0}');
      
      if (idToken == null || idToken.isEmpty) {
        throw const AuthApiException('Không thể lấy ID Token từ Google');
      }

      print('[DEBUG] Sending ID Token to backend...');
      final response = await _authApiService.loginWithGoogle(idToken);
      print('[DEBUG] Backend response received');

      final token = response.data?.token ?? '';
      if (token.isEmpty) {
        throw const AuthApiException('Không nhận được token từ server.');
      }

      final userInfo = response.data?.userInfo;
      await _tokenStorageService.saveAuthSession(
        token: token,
        userId: userInfo?.id,
        email: userInfo?.email,
        role: userInfo?.role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      final role = (userInfo?.role ?? 'USER').toUpperCase();
      Navigator.pushNamedAndRemoveUntil(
        context,
        role == 'ADMIN' ? AppRoutes.adminHome : AppRoutes.home,
        (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      print('[ERROR] AuthApiException: ${error.message}');
      final translated = ErrorTranslator.translate(error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translated), backgroundColor: Colors.redAccent),
      );
    } catch (error) {
      if (!mounted) return;
      print('[ERROR] Exception: $error');
      final translated = ErrorTranslator.translate(error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translated),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
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
              colors: [Color(0xFF0A132C), Color(0xFF151025)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF8B1F),
                              Color(0xFFE52E71)
                            ],
                          ),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Chào mừng trở lại',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập để tiếp tục hành trình của bạn',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFA7AEC1)),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMAIL',
                          style: TextStyle(
                            color: Color(0xFF8E97AE),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          autofocus: true,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'nguyenvana@example.com',
                            hintStyle:
                                const TextStyle(color: Color(0xFF7D8599)),
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Color(0xFF7D8599), size: 18),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: _emailError != null
                                  ? const BorderSide(
                                      color: Color(0xFFEF4444), width: 1.5)
                                  : BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                        if (_emailError != null)
                          FormErrorWidget(error: _emailError),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MẬT KHẨU',
                          style: TextStyle(
                            color: Color(0xFF8E97AE),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle:
                                const TextStyle(color: Color(0xFF7D8599)),
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
                            fillColor: Colors.black.withValues(alpha: 0.18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: _passwordError != null
                                  ? const BorderSide(
                                      color: Color(0xFFEF4444), width: 1.5)
                                  : BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: _passwordError != null
                                  ? const BorderSide(
                                      color: Color(0xFFEF4444), width: 1.5)
                                  : BorderSide.none,
                            ),
                          ),
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                        ),
                        if (_passwordError != null)
                          FormErrorWidget(error: _passwordError),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.forgotPassword),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(color: Color(0xFFC6CBE0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8B1F), Color(0xFFE52E71)],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : _submitLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
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
                                'Đăng nhập →',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'HOẶC TIẾP TỤC VỚI',
                            style: TextStyle(
                              color: Color(0xFF7E869A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: (_isLoading || _isGoogleLoading)
                          ? null
                          : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFEA4335),
                              ),
                            )
                          : const Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFFEA4335),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                      label: const Text('Google'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: Color(0xFFA6ADC0)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                          child: const Text(
                            'Đăng ký miễn phí',
                            style: TextStyle(
                              color: Color(0xFFFFB21F),
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }
}
