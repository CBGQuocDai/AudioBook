import 'user_response.dart';

class UpdateUserRequest {
  final String name;
  final String email;
  final String? password;
  final int avatarFileId;
  final RoleEnum role;

  UpdateUserRequest({
    required this.name,
    required this.email,
    this.password,
    required this.avatarFileId,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'email': email,
      'avatarFileId': avatarFileId,
      'role': role.toBackendValue(),
    };

    if (password != null && password!.trim().isNotEmpty) {
      data['password'] = password;
    }

    return data;
  }
}