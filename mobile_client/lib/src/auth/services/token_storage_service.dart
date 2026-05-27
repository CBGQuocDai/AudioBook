import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ lưu trữ Token và Thông tin phiên đăng nhập cục bộ.
///
/// Sử dụng [SharedPreferences] để lưu trữ an toàn các thông tin cấu hình phiên đăng nhập của người dùng.
class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  /// Lưu trữ Access Token vào bộ nhớ máy.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT token cần lưu trữ.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> saveToken(String token) async {
    await saveAuthSession(token: token);
  }

  /// Lưu trữ đầy đủ thông tin phiên đăng nhập (Token, UserID, Email, Role) vào bộ nhớ cục bộ.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token xác thực.
  ///   - [userId]: ID của người dùng.
  ///   - [email]: Email của tài khoản.
  ///   - [role]: Vai trò phân quyền của tài khoản.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
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

  /// Lấy Access Token đã lưu trữ trong máy.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<String?>] chứa JWT Token, hoặc `null` nếu chưa đăng nhập.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Lấy ID của người dùng đã lưu trong máy.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<int?>] ID người dùng, hoặc `null` nếu chưa có.
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Lấy email của tài khoản đã lưu trong máy.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<String?>] chứa email, hoặc `null` nếu chưa có.
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Lấy vai trò (Role) của tài khoản đã lưu trong máy.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<String?>] chứa vai trò, hoặc `null` nếu chưa có.
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Xóa toàn bộ thông tin phiên đăng nhập (Token, UserID, Email, Role) ra khỏi máy khi đăng xuất.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
  }
}
