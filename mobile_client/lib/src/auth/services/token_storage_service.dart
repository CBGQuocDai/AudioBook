import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  Future<void> saveToken(String token) async {
    await saveAuthSession(token: token);
  }

  Future<void> saveAuthSession({
    required String token,
    int? userId,
    String? email,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);

    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    } else {
      await prefs.remove(_userIdKey);
    }

    if (email != null && email.trim().isNotEmpty) {
      await prefs.setString(_userEmailKey, email.trim());
    } else {
      await prefs.remove(_userEmailKey);
    }

    if (role != null && role.trim().isNotEmpty) {
      await prefs.setString(_userRoleKey, role.trim());
    } else {
      await prefs.remove(_userRoleKey);
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
  }
}
