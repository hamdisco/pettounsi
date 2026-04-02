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
import 'services/post_outbox_service.dart';
import 'shell/main_scaffold.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      await FirebaseAppCheck.instance.activate(
        providerAndroid: providerAndroid,
        providerApple: providerApple,
      );
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
      onTimeout: () {
        debugPrint('PostOutboxService init timed out - continuing anyway');
      },
    );
  } catch (e, st) {
    debugPrint('PostOutboxService init failed: $e');
    FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
  }

  runApp(const PetTounsiApp());
}

class PetTounsiApp extends StatelessWidget {
  const PetTounsiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Pettounsi",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
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