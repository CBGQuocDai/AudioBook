import 'package:mobile_client/src/auth/models/otp_purpose.dart';

class VerifyOtpArgs {
  final String email;
  final OtpPurpose otpPurpose;

  const VerifyOtpArgs({
    required this.email,
    required this.otpPurpose,
  });
}
