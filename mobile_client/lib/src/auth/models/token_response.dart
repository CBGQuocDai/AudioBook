import 'package:mobile_client/src/auth/models/user_info.dart';

class TokenResponse {
  final String token;
  final String? refreshToken;
  final UserInfo? userInfo;

  const TokenResponse({
    required this.token,
    this.refreshToken,
    this.userInfo,
  });

  String get accessToken => token;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    final userInfoRaw = json['userInfo'];
    return TokenResponse(
      token: (json['token'] ?? json['accessToken'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
      userInfo: userInfoRaw is Map<String, dynamic>
          ? UserInfo.fromJson(userInfoRaw)
          : null,
    );
  }
}
