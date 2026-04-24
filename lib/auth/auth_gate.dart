import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/compliance/compliance_gate.dart';
import '../services/auth_service.dart';
import '../services/connectivity_status_controller.dart';
import '../services/user_profile_service.dart';
import '../shell/main_scaffold.dart';
import '../ui/app_theme.dart';
import '../ui/offline_feedback.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  static const String route = "/";

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ConnectivityStatusController.instance,
      builder: (context, _) {
        return StreamBuilder<User?>(
          stream: AuthService.instance.authStateChanges(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              final offline = ConnectivityStatusController.instance.isOffline;
              return Scaffold(
                backgroundColor: AppTheme.bg,
                body: offline
                    ? const SafeArea(
                        child: OfflinePageState(
                          title: "You're offline",
                          subtitle:
                              'We could not check your session right now. Reconnect to continue if nothing is saved yet.',
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              );
            }

            final user = snap.data;
            if (user == null) return const LoginPage();

            return FutureBuilder(
              future: UserProfileService.instance.ensureUserDoc(user),
              builder: (context, pSnap) {
                if (pSnap.connectionState == ConnectionState.waiting) {
                  final offline = ConnectivityStatusController.instance.isOffline;
                  return Scaffold(
                    backgroundColor: AppTheme.bg,
                    body: offline
                        ? const SafeArea(
                            child: OfflinePageState(
                              title: 'Profile data is unavailable offline',
                              subtitle:
                                  'We could not finish loading your account setup. Reconnect to continue.',
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  );
                }

                return const ComplianceGate(child: MainScaffold());
              },
            );
          },
        );
      },
    );
  }
}
