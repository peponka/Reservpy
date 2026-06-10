import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reservpy/src/core/supabase/supabase_config.dart';

class AuthRepository {
  final _auth = SupabaseConfig.auth;

  /// Current session
  Session? get currentSession => _auth.currentSession;
  
  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String role = 'client',
    String? businessName,
    String? categoryId,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'role': role,
        // Guardamos nombre + rubro del negocio para pre-cargar el onboarding
        if (businessName != null && businessName.isNotEmpty)
          'business_name': businessName,
        if (categoryId != null && categoryId.isNotEmpty)
          'category_id': categoryId,
      },
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: Supabase OAuth redirect flow — uses registered redirect URI,
      // no JavaScript origin propagation needed.
      try {
        await _auth.signInWithOAuth(OAuthProvider.google);
        return true; // Browser redirects immediately; session handled by app.dart listener
      } catch (_) {
        return false;
      }
    }

    // Android/iOS: native Google Sign-In → Supabase signInWithIdToken
    const webClientId = '412493608107-93hftd0m1l7bavll2u0j2pgsecei6ibj.apps.googleusercontent.com';
    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: ['email', 'profile', 'openid'],
    );
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return false;
      await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  /// Update user metadata
  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return await _auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: data,
      ),
    );
  }
}
