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
      return await _googleSignIn.signIn();
    } catch (error) {
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

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (error) {
      return false;
    }
  }
}
