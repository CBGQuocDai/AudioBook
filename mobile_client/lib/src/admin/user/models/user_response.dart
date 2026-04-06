import 'file_dto.dart';

enum RoleEnum {
  admin,
  user;

  factory RoleEnum.fromString(String? value) {
    switch ((value ?? 'USER').toUpperCase()) {
      case 'ADMIN':
        return RoleEnum.admin;
      case 'USER':
      default:
        return RoleEnum.user;
    }
  }

  String toBackendValue() {
    switch (this) {
      case RoleEnum.admin:
        return 'ADMIN';
      case RoleEnum.user:
        return 'USER';
    }
  }

  String get displayName {
    switch (this) {
      case RoleEnum.admin:
        return 'ADMIN';
      case RoleEnum.user:
        return 'USER';
    }
  }
}

class UserResponse {
  final int id;
  final String email;
  final String name;
  final FileDto? avatarFile;
  final String? avatarUrl;
  final RoleEnum role;
  final bool? active;

  UserResponse({
    required this.id,
    required this.email,
    required this.name,
    this.avatarFile,
    this.avatarUrl,
    required this.role,
    this.active,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatarFile: json['avatarFile'] != null
          ? FileDto.fromJson(json['avatarFile'] as Map<String, dynamic>)
          : null,
      avatarUrl: json['avatarUrl'],
      role: RoleEnum.fromString(json['role']),
      active: json['active'] is bool ? json['active'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarFile': avatarFile?.toJson(),
      'avatarUrl': avatarUrl,
      'role': role.toBackendValue(),
      'active': active,
    };
  }

  String? get displayAvatar {
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return avatarUrl;
    }
    if (avatarFile?.filePath != null && avatarFile!.filePath!.trim().isNotEmpty) {
      return avatarFile!.filePath;
    }
    return null;
  }
}