import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/login_request.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
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

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService(baseUrl: _baseUrl);
  final TokenStorageService _tokenStorageService = TokenStorageService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authApiService.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      final token = response.data?.token ?? '';
      if (token.isEmpty) {
        throw const AuthApiException('Không nhận được token từ server.');
      }

      await _tokenStorageService.saveToken(token);
      final role = (response.data?.userInfo?.role ?? 'USER').toUpperCase();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        role == 'ADMIN' ? AppRoutes.adminHome : AppRoutes.home,
            (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
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
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu tối thiểu 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitLogin,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Đăng nhập'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text('Đăng ký'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}