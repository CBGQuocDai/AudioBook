import 'package:mobile_client/src/auth/models/user_info.dart';

/// Lớp chứa thông tin phản hồi khi đăng nhập thành công bao gồm token xác thực và thông tin người dùng.
class TokenResponse {
  /// Mã JWT Token dùng để xác thực các yêu cầu API tiếp theo.
  final String token;

  /// Mã Token dùng để làm mới access token khi hết hạn (nếu có).
  final String? refreshToken;

  /// Thông tin chi tiết của người dùng đăng nhập.
  final UserInfo? userInfo;

  /// Khởi tạo đối tượng [TokenResponse].
  const TokenResponse({
    required this.token,
    this.refreshToken,
    this.userInfo,
  });

  /// Getter trả về Access Token (alias cho trường [token]).
  String get accessToken => token;

  /// Tạo đối tượng [TokenResponse] từ dữ liệu định dạng JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ [Map] chứa dữ liệu JSON từ API phản hồi.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [TokenResponse].
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
