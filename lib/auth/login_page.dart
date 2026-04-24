import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import '../ui/brand_widgets.dart';
import '../ui/cat_mascot.dart';
import '../ui/app_theme.dart';
import '../services/auth_service.dart';
import '../core/auth_error_text.dart';
import 'signup_page.dart';
import 'auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const String route = "/login";

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();

  final emailF = FocusNode();
  final passF = FocusNode();

  bool showPassword = false;
  bool loading = false;

  double look = 0;
  bool eyesClosed = false;

  bool get _showAppleButton =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();

    emailF.addListener(_syncMascot);
    passF.addListener(_syncMascot);

    emailC.addListener(() {
      final len = emailC.text.length.clamp(0, 30);
      setState(() => look = (len / 30) * 2 - 1);
    });

    _syncMascot();
  }

  void _syncMascot() {
    setState(() {
      eyesClosed = passF.hasFocus && !showPassword;
      if (passF.hasFocus) look = 0.0;
    });
  }

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    emailF.dispose();
    passF.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loginEmail() async {
    setState(() => loading = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: emailC.text,
        password: passC.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AuthGate.route,
        (r) => false,
      );
    } catch (e) {
      _toast(authErrorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AuthGate.route,
        (r) => false,
      );
    } catch (e) {
      _toast(authErrorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginApple() async {
    setState(() => loading = true);
    try {
      await AuthService.instance.signInWithApple();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AuthGate.route,
        (r) => false,
      );
    } catch (e) {
      _toast(authErrorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: BrandAuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CatMascot(look: look, eyesClosed: eyesClosed),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Sign in",
                      style: t.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showAppleButton) ...[
                            AppleButton(
                              onPressed: loading ? () {} : _loginApple,
                            ),
                            const SizedBox(height: 10),
                          ],
                          GoogleButton(
                            onPressed: loading ? () {} : _loginGoogle,
                          ),
                          const SizedBox(height: 14),
                          const OrDivider(),
                          const SizedBox(height: 14),

                          AuthField(
                            label: "Email",
                            icon: Icons.mail_outline,
                            controller: emailC,
                            focusNode: emailF,
                          ),
                          const SizedBox(height: 12),

                          AuthField(
                            label: "Password",
                            icon: Icons.lock_outline,
                            controller: passC,
                            focusNode: passF,
                            obscure: !showPassword,
                            suffix: IconButton(
                              onPressed: () {
                                setState(() => showPassword = !showPassword);
                                _syncMascot();
                              },
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: showPassword,
                                onChanged: (v) {
                                  setState(() => showPassword = v ?? false);
                                  _syncMascot();
                                },
                              ),
                              const Text(
                                "Show password",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  if (emailC.text.trim().isEmpty) {
                                    _toast("Type your email first.");
                                    return;
                                  }
                                  try {
                                    await AuthService.instance
                                        .sendPasswordReset(emailC.text);
                                    _toast("Password reset email sent.");
                                  } catch (e) {
                                    _toast(authErrorText(e));
                                  }
                                },
                                child: const Text("Forgot password?"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          PrimaryCTA(
                            text: "SIGN IN",
                            onPressed: _loginEmail,
                            loading: loading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, SignUpPage.route),
                        child: const Text("Create an account"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
