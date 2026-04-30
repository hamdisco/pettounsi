import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'auth/auth_gate.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'core/app_config.dart';
import 'firebase_options.dart';
import 'services/app_theme_controller.dart';
import 'services/connectivity_status_controller.dart';
import 'services/post_outbox_service.dart';
import 'shell/main_scaffold.dart';
import 'ui/app_theme.dart';
import 'ui/offline_banner_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<void> _bootstrapFuture = _bootstrap();

  Future<void> _bootstrap() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 12));

    await AppThemeController.instance.load().timeout(
      const Duration(seconds: 5),
    );
    await ConnectivityStatusController.instance.start().timeout(
      const Duration(seconds: 6),
    );

    try {
      debugPrint(
        '[CONFIG] cloudinaryDefined=${AppConfig.cloudinaryCloudName.isNotEmpty && AppConfig.cloudinaryUploadPreset.isNotEmpty}',
      );
    } catch (_) {}

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    const enableAppCheck = bool.fromEnvironment(
      'ENABLE_APP_CHECK',
      defaultValue: false,
    );
    const appCheckDebug = bool.fromEnvironment(
      'APP_CHECK_DEBUG',
      defaultValue: false,
    );

    if (enableAppCheck) {
      final AndroidAppCheckProvider providerAndroid = appCheckDebug
          ? const AndroidDebugProvider()
          : (kReleaseMode
                ? const AndroidPlayIntegrityProvider()
                : const AndroidDebugProvider());
      final AppleAppCheckProvider providerApple = appCheckDebug
          ? const AppleDebugProvider()
          : (kReleaseMode
                ? const AppleDeviceCheckProvider()
                : const AppleDebugProvider());

      try {
        await FirebaseAppCheck.instance
            .activate(
              providerAndroid: providerAndroid,
              providerApple: providerApple,
            )
            .timeout(const Duration(seconds: 8));
        debugPrint(
          'AppCheck activated: android=$providerAndroid apple=$providerApple',
        );
      } catch (e, st) {
        debugPrint('AppCheck activation failed: $e');
        FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      }
    } else {
      debugPrint('AppCheck disabled (ENABLE_APP_CHECK=false).');
    }

    try {
      await PostOutboxService.instance.init().timeout(
        const Duration(seconds: 5),
      );
    } catch (e, st) {
      debugPrint('PostOutboxService init failed: $e');
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Starting Pettounsi...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Startup failed:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        return const PetTounsiApp();
      },
    );
  }
}

class PetTounsiApp extends StatefulWidget {
  const PetTounsiApp({super.key});

  @override
  State<PetTounsiApp> createState() => _PetTounsiAppState();
}

class _PetTounsiAppState extends State<PetTounsiApp> {
  @override
  void initState() {
    super.initState();
    AppThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    AppThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pettounsi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: AppThemeController.instance.themeMode,
      builder: (context, child) =>
          OfflineBannerOverlay(child: child ?? const SizedBox.shrink()),
      initialRoute: AuthGate.route,
      routes: {
        AuthGate.route: (_) => const AuthGate(),
        LoginPage.route: (_) => const LoginPage(),
        SignUpPage.route: (_) => const SignUpPage(),
        MainScaffold.route: (_) => const MainScaffold(),
      },
    );
  }
}
