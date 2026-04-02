import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

String authErrorText(Object e) {
  final type = e.runtimeType.toString();

  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return "Invalid email address.";
      case 'user-not-found':
        return "No account found for this email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'email-already-in-use':
        return "This email is already used.";
      case 'weak-password':
        return "Password is too weak (try 6+ characters).";
      case 'network-request-failed':
        return "Network error. Check your internet connection.";
      case 'canceled':
      case 'web-context-cancelled':
        return "Sign-in canceled.";
      case 'operation-not-allowed':
        return "This sign-in method is not enabled yet in Firebase Auth.";
      case 'account-exists-with-different-credential':
        return "An account already exists with the same email using a different sign-in method.";
      default:
        return "FirebaseAuthException(${e.code}): ${e.message ?? ''}";
    }
  }

  if (e is PlatformException) {
    return "PlatformException(${e.code}) [${e.message ?? ''}] details=${e.details}";
  }

  return "$type: $e";
}
