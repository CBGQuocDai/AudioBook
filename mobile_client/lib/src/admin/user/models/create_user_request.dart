import 'user_response.dart';

class CreateUserRequest {
  final String name;
  final String email;
  final String password;
  final int avatarFileId;
  final RoleEnum role;

  CreateUserRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.avatarFileId,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'avatarFileId': avatarFileId,
      'role': role.toBackendValue(),
    };
  }
}