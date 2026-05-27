import 'package:google_sign_in/google_sign_in.dart';

/// Dịch vụ xử lý đăng nhập thông qua tài khoản Google (Google Sign-In).
///
/// Hỗ trợ đăng nhập, đăng xuất, lấy thông tin người dùng hiện tại và lấy mã xác thực ID Token.
class GoogleAuthService {
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '464204505958-tkr8t1c9gfla01kqmuom6thrdnqjgpgj.apps.googleusercontent.com',
  );

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Bắt đầu quy trình đăng nhập Google bằng cách hiển thị hộp thoại đăng nhập cho người dùng.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<GoogleSignInAccount?>] chứa thông tin tài khoản nếu thành công, hoặc `null` nếu người dùng hủy.
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      rethrow;
    }
  }

  /// Lấy thông tin tài khoản Google đã đăng nhập hiện tại bằng cách chạy chế độ đăng nhập im lặng (silent sign-in).
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<GoogleSignInAccount?>] nếu tài khoản đã được xác thực trước đó.
  static Future<GoogleSignInAccount?> get currentUser =>
      _googleSignIn.signInSilently();

  /// Đăng xuất tài khoản Google hiện tại ra khỏi ứng dụng.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      rethrow;
    }
  }

  /// Lấy mã định danh ID Token từ phiên đăng nhập Google để gửi lên Backend.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<String?>] chứa ID Token, hoặc `null` nếu không tìm thấy phiên đăng nhập.
  static Future<String?> getIdToken() async {
    try {
      final account = _googleSignIn.currentUser;
      
      if (account == null) {
        final silentAccount = await _googleSignIn.signInSilently();
        if (silentAccount == null) {
          return null;
        }
        final auth = await silentAccount.authentication;
        return auth.idToken;
      }
      
      final auth = await account.authentication;
      return auth.idToken;
    } catch (error) {
      rethrow;
    }
  }

  /// Kiểm tra xem người dùng hiện tại đã đăng nhập tài khoản Google hay chưa.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<bool>] (`true` nếu đã đăng nhập, ngược lại `false`).
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (error) {
      return false;
    }
  }
}
