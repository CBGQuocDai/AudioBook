import 'package:mobile_client/src/auth/models/avatar_file.dart';

/// Lớp mô tả thông tin chi tiết cá nhân của người dùng hệ thống.
class UserInfo {
  /// ID duy nhất của người dùng.
  final int? id;

  /// Địa chỉ email đăng ký tài khoản.
  final String email;

  /// Tên hiển thị của người dùng.
  final String? name;

  /// Đối tượng [AvatarFile] mô tả tệp ảnh đại diện của người dùng.
  final AvatarFile? avatarFile;

  /// Đường dẫn đầy đủ trỏ tới ảnh đại diện trực tuyến.
  final String? avatarUrl;

  /// Vai trò phân quyền của người dùng (Ví dụ: 'user', 'admin').
  final String? role;

  /// Cấp bậc hội viên (Ví dụ: 'free', 'premium').
  final String? tier;

  /// Tổng số xu/credit khả dụng của người dùng.
  final int totalCredit;

  /// Khởi tạo [UserInfo] với các giá trị cung cấp.
  const UserInfo({
    this.id,
    required this.email,
    this.name,
    this.avatarFile,
    this.avatarUrl,
    this.role,
    this.tier,
    this.totalCredit = 0,
  });

  /// Tạo đối tượng [UserInfo] từ dữ liệu định dạng JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ [Map] chứa dữ liệu JSON từ API phản hồi.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [UserInfo].
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    final avatarFileRaw = json['avatarFile'];
    return UserInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      avatarFile: avatarFileRaw is Map<String, dynamic>
          ? AvatarFile.fromJson(avatarFileRaw)
          : null,
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role']?.toString(),
      tier: json['tier']?.toString(),
      totalCredit: json['totalCredit'] is int
          ? json['totalCredit'] as int
          : int.tryParse('${json['totalCredit']}') ?? 0,
    );
  }
}
