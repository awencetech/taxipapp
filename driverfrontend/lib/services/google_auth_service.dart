import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class GoogleAuthService {
  static const String _clientId =
      "996214358508-qiq5q5lovamh98dio6sj27ps69pm8evk.apps.googleusercontent.com";

  late final GoogleSignIn _googleSignIn;

  GoogleAuthService() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? _clientId : null,
      scopes: ['email', 'profile'],
    );
  }

  Future<Map<String, dynamic>?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;

      return {
        'email': account.email,
        'name': account.displayName,
        'googleId': account.id,
        'photoUrl': account.photoUrl,
        'idToken': auth.idToken,
        'accessToken': auth.accessToken,
      };
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Google Sign-Out Error: $error');
    }
  }
}
