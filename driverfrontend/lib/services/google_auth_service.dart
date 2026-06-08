import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class GoogleAuthService {
  static const String _clientId =
      "853680153976-bcn1s55141qhvn240c294qa5i85dva3o.apps.googleusercontent.com";

  late final GoogleSignIn _googleSignIn;

  GoogleAuthService() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? _clientId : null,
      scopes: ['email', 'profile'],
    );
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
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
