import 'package:google_sign_in/google_sign_in.dart';

/// Service to handle Google Sign-In authentication
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

  /// Sign in with Google and return authentication tokens
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      print('[GoogleAuthService] Calling GoogleSignIn.signIn()...');
      final account = await _googleSignIn.signIn();
      print('[GoogleAuthService] signIn() completed. Account: ${account?.email}');
      return account;
    } catch (error) {
      print('[GoogleAuthService] signIn() error: $error');
      rethrow;
    }
  }

  /// Get current signed-in account
  static Future<GoogleSignInAccount?> get currentUser =>
      _googleSignIn.signInSilently();

  /// Sign out from Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      rethrow;
    }
  }

  /// Get ID token for authentication
  static Future<String?> getIdToken() async {
    try {
      print('[GoogleAuthService] Getting current account...');
      final account = _googleSignIn.currentUser;
      print('[GoogleAuthService] Current account: ${account?.email}');
      
      if (account == null) {
        print('[GoogleAuthService] No account found, trying signInSilently...');
        final silentAccount = await _googleSignIn.signInSilently();
        if (silentAccount == null) {
          print('[GoogleAuthService] signInSilently failed - no account');
          return null;
        }
        final auth = await silentAccount.authentication;
        print('[GoogleAuthService] Got auth from silentAccount. idToken length: ${auth.idToken?.length ?? 0}');
        return auth.idToken;
      }
      
      print('[GoogleAuthService] Getting authentication from current account...');
      final auth = await account.authentication;
      print('[GoogleAuthService] Got authentication. idToken length: ${auth.idToken?.length ?? 0}');
      return auth.idToken;
    } catch (error) {
      print('[GoogleAuthService] getIdToken error: $error');
      rethrow;
    }
  }

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (error) {
      return false;
    }
  }
}
