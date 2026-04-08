import 'package:mobile_client/src/auth/models/avatar_file.dart';

class UserInfo {
  final int? id;
  final String email;
  final String? name;
  final AvatarFile? avatarFile;
  final String? avatarUrl;
  final String? role;
  final String? tier;
  final int totalCredit;

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
