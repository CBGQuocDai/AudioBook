import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_client/src/auth/models/otp_purpose.dart';
import 'package:mobile_client/src/auth/models/recover_password_args.dart';
import 'package:mobile_client/src/auth/models/otp_request.dart';
import 'package:mobile_client/src/auth/models/verify_otp_args.dart';
import 'package:mobile_client/src/auth/models/verify_otp_request.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/client_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
import 'package:mobile_client/src/util/routes.dart';

/// Màn hình xác thực mã OTP.
///
/// Dùng để nhập và gửi mã OTP gồm 6 chữ số nhằm phục vụ các quy trình:
/// 1. Xác minh email khi đăng ký tài khoản ([OtpPurpose.verifyEmail]).
/// 2. Xác thực để đặt lại mật khẩu ([OtpPurpose.resetPassword]).
/// 3. Xác thực khi thay đổi địa chỉ email ([OtpPurpose.changeEmail]).
class VerifyOtpScreen extends StatefulWidget {
  /// Khởi tạo [VerifyOtpScreen].
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
  final ClientApiService _clientApiService = ClientApiService(baseUrl: _baseUrl);
  final TokenStorageService _tokenStorageService = TokenStorageService();
  bool _isLoading = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  /// Trích xuất tham số truyền đến màn hình này.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [context]: Ngữ cảnh BuildContext hiện tại.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [VerifyOtpArgs]. Nếu null, trả về giá trị mặc định trống.
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

  /// Bắt đầu đếm ngược thời gian hết hạn mã OTP và cho phép gửi lại mã sau khi kết thúc.
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

  /// Định dạng số giây đếm ngược thành định dạng Phút:Giây (MM:SS).
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [seconds]: Số giây cần định dạng.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về chuỗi [String] định dạng dạng `05:00`.
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

  /// Gửi mã OTP đã nhập lên server để thực hiện kiểm tra và xác thực.
  ///
  /// Phương thức này thực hiện:
  /// 1. Gọi API tương ứng dựa theo mục đích sử dụng mã [args.otpPurpose].
  /// 2. Đối với thay đổi email: Gọi [ClientApiService.changeEmail] và lưu session mới.
  /// 3. Đối với xác minh email: Gọi [AuthApiService.verifyOtp], sau đó kích hoạt tài khoản và điều hướng về [AppRoutes.login].
  /// 4. Đối với quên mật khẩu: Xác thực OTP thành công sẽ điều hướng người dùng tới [AppRoutes.recoverPassword].
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [args]: Chứa email và mục đích OTP.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
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

        final changeEmailResponse = await _clientApiService.changeEmail(
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

  /// Yêu cầu hệ thống gửi lại mã OTP mới.
  ///
  /// Thực hiện gửi lại mã OTP phù hợp với mục đích sử dụng hiện tại ([args.otpPurpose]).
  /// Sau khi gửi lại thành công, khởi động lại bộ đếm thời gian đếm ngược.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [args]: Chứa email và mục đích OTP.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
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
        await _clientApiService.preChangeEmail(
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
