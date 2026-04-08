import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_client/src/auth/models/otp_purpose.dart';
import 'package:mobile_client/src/auth/models/recover_password_args.dart';
import 'package:mobile_client/src/auth/models/otp_request.dart';
import 'package:mobile_client/src/auth/models/verify_otp_args.dart';
import 'package:mobile_client/src/auth/models/verify_otp_request.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
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
  final FocusNode _otpFocusNode = FocusNode();
  final AuthApiService _authApiService = AuthApiService(baseUrl: _baseUrl);
  final TokenStorageService _tokenStorageService = TokenStorageService();
  bool _isLoading = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

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

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 300;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Bắt buộc phải kiểm tra mounted trước khi gọi setState trong Timer
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitOtp(VerifyOtpArgs args) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (args.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thiếu email xác thực, vui lòng thử lại.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (args.otpPurpose == OtpPurpose.changeEmail) {
        final token = await _tokenStorageService.getToken();
        if (token == null || token.isEmpty) {
          throw const AuthApiException('Phiên đăng nhập đã hết hạn.');
        }

        final changeEmailResponse = await _authApiService.changeEmail(
          token: token,
          otp: _otpController.text.trim(),
          newEmail: args.email,
        );

        final newToken = changeEmailResponse.data?.token ?? '';
        final userInfo = changeEmailResponse.data?.userInfo;
        if (newToken.isNotEmpty) {
          await _tokenStorageService.saveAuthSession(
            token: newToken,
            userId: userInfo?.id,
            email: userInfo?.email,
            role: userInfo?.role,
          );
        }

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(changeEmailResponse.message)),
        );
        Navigator.popUntil(
          context,
          ModalRoute.withName(AppRoutes.profile),
        );
        return;
      }

      final response = await _authApiService.verifyOtp(
        VerifyOtpRequest(
          otp: _otpController.text.trim(),
          email: args.email,
          otpPurpose: args.otpPurpose,
        ),
      );

      if (args.otpPurpose == OtpPurpose.verifyEmail) {
        final token = response.data?.token ?? '';
        if (token.isEmpty) {
          throw const AuthApiException(
            'Không nhận được token xác thực từ server.',
          );
        }
        await _authApiService.activeAccount(token);
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
        return;
      }

      final token = response.data?.token ?? '';
      if (token.isEmpty) {
        throw const AuthApiException('Không nhận được token reset từ server.');
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.recoverPassword,
        arguments: RecoverPasswordArgs(
          token: token,
          email: args.email,
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

  Future<void> _resendOtp(VerifyOtpArgs args) async {
    if (args.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu email để gửi lại OTP.')),
      );
      return;
    }

    try {
      if (args.otpPurpose == OtpPurpose.resetPassword) {
        await _authApiService.forgotPassword(OtpRequest(email: args.email));
      } else if (args.otpPurpose == OtpPurpose.changeEmail) {
        final token = await _tokenStorageService.getToken();
        if (token == null || token.isEmpty) {
          throw const AuthApiException('Phiên đăng nhập đã hết hạn.');
        }
        await _authApiService.preChangeEmail(
          token: token,
          newEmail: args.email,
        );
      } else {
        await _authApiService.requestOtp(OtpRequest(email: args.email));
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại OTP.')),
      );
      _startResendCountdown();
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      final message = ErrorTranslator.translate(error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _resolveArgs(context);
    final otpValue = _otpController.text.trim();
    final displayOtp = otpValue.padRight(6, ' ');

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
                  child: GestureDetector(
                    onTap: () => _otpFocusNode.requestFocus(),
                    child: Container(
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
                              ],
                            ),
                            const SizedBox(height: 80),
                            const Text(
                              'Xác thực ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 40,
                              ),
                            ),
                            const Text(
                              'mã',
                              style: TextStyle(
                                color: Color(0xFFE84A6A),
                                fontWeight: FontWeight.w700,
                                fontSize: 40,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Chúng tôi đã gửi mã xác thực đến\n${args.email}',
                              style: const TextStyle(
                                color: Color(0xFFA8AEC1),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _otpController,
                              focusNode: _otpFocusNode,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              style: const TextStyle(
                                  color: Colors.transparent, fontSize: 1),
                              cursorColor: Colors.transparent,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final otp = value?.trim() ?? '';
                                if (otp.length != 6) {
                                  return 'OTP phải gồm đúng 6 số';
                                }
                                return null;
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                final char = displayOtp[index];
                                final filled = char.trim().isNotEmpty;
                                return Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A2540),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: filled
                                              ? const Color(0xFFFF8B1F)
                                              : Colors.white12,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        filled ? char : '•',
                                        style: TextStyle(
                                          color: filled
                                              ? Colors.white
                                              : const Color(0xFF5A6B82),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Text(
                                _resendCountdown > 0
                                    ? 'Mã sẽ hết hạn trong ${_formatCountdown(_resendCountdown)}'
                                    : 'Mã đã hết hạn',
                                style: const TextStyle(
                                  color: Color(0xFF8D95A8),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8B1F),
                                    Color(0xFFE52E71)
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : () => _submitOtp(args),
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
                                        'Xác nhận  →',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  const Text(
                                    'Không nhận được mã? ',
                                    style: TextStyle(
                                      color: Color(0xFF8D95A8),
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _resendCountdown > 0
                                        ? null
                                        : () => _resendOtp(args),
                                    child: Text(
                                      'Gửi lại',
                                      style: TextStyle(
                                        color: _resendCountdown > 0
                                            ? const Color(0xFF5A6B82)
                                            : const Color(0xFFFF8B1F),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
