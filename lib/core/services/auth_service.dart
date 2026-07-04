import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // ── Email/Password ──────────────────────────────────────────────────
  static Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'phone': phone},
      );

  static Future<void> signOut() => _client.auth.signOut();

  // ── Google ──────────────────────────────────────────────────────────
  static Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: authRedirectUrl,
      );
      return;
    }
    // Native flow (Android / iOS)
    const webClientId =
        'VOTRE_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';
    const iosClientId =
        'VOTRE_GOOGLE_IOS_CLIENT_ID.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Connexion Google annulée');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) throw Exception('Token Google manquant');

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // ── Facebook ─────────────────────────────────────────────────────────
  static Future<void> signInWithFacebook() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? null : authRedirectUrl,
    );
  }

  // ── Apple ────────────────────────────────────────────────────────────
  static Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : authRedirectUrl,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────
  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
