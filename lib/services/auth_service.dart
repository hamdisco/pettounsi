import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(username.trim());
    return cred;
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'canceled',
        message: 'Google sign-in canceled',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    return _auth.signInWithCredential(oauthCredential);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> sendPasswordReset(String email) {
    const continueUrl = 'https://pettounsi-d3d5e.web.app';
    const androidPkg = 'com.pettounsi.app';

    final settings = ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: false,
      androidPackageName: androidPkg,
      androidInstallApp: false,
      androidMinimumVersion: '1',
    );

    return _auth.sendPasswordResetEmail(
      email: email.trim(),
      actionCodeSettings: settings,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final u = _auth.currentUser;
    if (u == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
    }

    final email = (u.email ?? '').trim();
    if (email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'This account has no email address',
      );
    }

    final hasPasswordProvider = u.providerData.any(
      (p) => p.providerId == 'password',
    );
    if (!hasPasswordProvider) {
      throw FirebaseAuthException(
        code: 'provider-not-password',
        message: 'This account uses a social login provider',
      );
    }

    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await u.reauthenticateWithCredential(cred);
    await u.updatePassword(newPassword);
    await u.reload();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }
}
