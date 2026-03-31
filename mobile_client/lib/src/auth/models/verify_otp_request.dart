import 'package:mobile_client/src/auth/models/otp_purpose.dart';

class VerifyOtpRequest {
  final String otp;
  final String email;
  final OtpPurpose otpPurpose;

  const VerifyOtpRequest({
    required this.otp,
    required this.email,
    required this.otpPurpose,
  });

  Map<String, dynamic> toJson() {
    return {
      'otp': otp,
      'email': email,
      'otpPurpose': otpPurpose.value,
    };
  }
}
