import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class GoogleAuthService {
  static const String _clientId =
      "1019476576912-mj1gij1eapfqgm2tl27nujd0qh720tjj.apps.googleusercontent.com";

  late final GoogleSignIn _googleSignIn;

  // Singleton pattern
  GoogleAuthService._privateConstructor() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? _clientId : null,
      scopes: ['email', 'profile'],
    );
  }

  static final GoogleAuthService _instance = GoogleAuthService._privateConstructor();

  factory GoogleAuthService() {
    return _instance;
  }

  Future<Map<String, dynamic>?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      final GoogleSignInAuthentication authentication =
          await account.authentication;
      debugPrint('Google Auth: idToken=${authentication.idToken}, accessToken=${authentication.accessToken}');
      debugPrint('Google Account: email=${account.email}, name=${account.displayName}, photoUrl=${account.photoUrl}');
      
      final String? idToken = authentication.idToken;
      final String? accessToken = authentication.accessToken;

      if (idToken == null && accessToken == null) {
        debugPrint('Both Google ID token and access token are null');
        return null;
      }

      return {
        'googleToken': idToken ?? accessToken,
        'email': account.email,
        'name': account.displayName,
        'photoUrl': account.photoUrl,
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
