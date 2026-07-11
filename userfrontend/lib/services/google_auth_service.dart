import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_core/firebase_core.dart';

class GoogleAuthService {
  static const String _clientId =
      "996214358508-qiq5q5lovamh98dio6sj27ps69pm8evk.apps.googleusercontent.com";

  late final GoogleSignIn _googleSignIn;

  // Singleton pattern
  GoogleAuthService._privateConstructor() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? _clientId : null,
      scopes: ['email', 'profile'],
    );
    _printDebugInfo();
  }

  static final GoogleAuthService _instance = GoogleAuthService._privateConstructor();

  factory GoogleAuthService() {
    return _instance;
  }

  Future<void> _printDebugInfo() async {
    // Print debug info on startup
    debugPrint("=== Google Sign-In Debug Info ===");
    debugPrint("Package Name: com.taxinanban.user");
    debugPrint("SHA-1: 69:9A:92:DA:0F:E4:57:BC:4B:04:FB:C2:01:C0:A3:CB:F9:F6:A5:9D");
    try {
      final app = Firebase.app();
      debugPrint("Firebase App ID: ${app.options.appId}");
    } catch (e) {
      debugPrint("Firebase App not initialized: $e");
    }
    debugPrint("=================================");
  }

  Future<Map<String, dynamic>?> signIn() async {
    try {
      debugPrint("Starting Google Sign-In...");
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      debugPrint("Selected account: ${account?.email}");
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
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
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
