import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/compliance/compliance_gate.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../shell/main_scaffold.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  static const String route = "/";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) return const LoginPage();

        return FutureBuilder(
          future: UserProfileService.instance.ensureUserDoc(user),
          builder: (context, pSnap) {
            if (pSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const ComplianceGate(child: MainScaffold());
          },
        );
      },
    );
  }
}
