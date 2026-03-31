import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/otp_purpose.dart';
import 'package:mobile_client/src/auth/models/otp_request.dart';
import 'package:mobile_client/src/auth/models/verify_otp_args.dart';
import 'package:mobile_client/src/auth/models/verify_otp_request.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/util/routes.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService(baseUrl: _baseUrl);
  bool _isLoading = false;
  bool _isResending = false;

  VerifyOtpArgs _resolveArgs(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is VerifyOtpArgs) {
      return arguments;
    }
    return const VerifyOtpArgs(
      email: '',
      otpPurpose: OtpPurpose.verifyEmail,
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitOtp(VerifyOtpArgs args) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (args.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu email xác thực, vui lòng thử lại.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authApiService.verifyOtp(
        VerifyOtpRequest(
          otp: _otpController.text.trim(),
          email: args.email,
          otpPurpose: args.otpPurpose,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp(VerifyOtpArgs args) async {
    if (args.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu email để gửi lại OTP.')),
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      if (args.otpPurpose == OtpPurpose.resetPassword) {
        await _authApiService.forgotPassword(OtpRequest(email: args.email));
      } else {
        await _authApiService.requestOtp(OtpRequest(email: args.email));
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại OTP.')),
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _resolveArgs(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nhập mã OTP gồm 6 số đã gửi đến email của bạn.',
                ),
                if (args.email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Email: ${args.email}'),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Mã OTP',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) {
                    final otp = value?.trim() ?? '';
                    if (otp.isEmpty) {
                      return 'Vui lòng nhập OTP';
                    }
                    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                      return 'OTP phải gồm đúng 6 số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitOtp(args),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xác thực'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isResending ? null : () => _resendOtp(args),
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi lại OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}