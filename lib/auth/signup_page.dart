import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import '../ui/brand_widgets.dart';
import '../ui/cat_mascot.dart';
import '../ui/app_theme.dart';
import '../services/auth_service.dart';
import '../core/auth_error_text.dart';
import 'auth_widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  static const String route = "/signup";

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final userC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();

  final userF = FocusNode();
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

    for (final f in [userF, emailF, passF]) {
      f.addListener(_syncMascot);
    }

    userC.addListener(_updateMascotLookFromActiveField);
    emailC.addListener(_updateMascotLookFromActiveField);

    _syncMascot();
  }

  void _updateMascotLookFromActiveField() {
    if (!mounted) return;

    if (passF.hasFocus) {
      setState(() => look = 0.0);
      return;
    }

    if (userF.hasFocus) {
      final len = userC.text.trim().length.clamp(0, 20);
      setState(() => look = (len / 20) * 2 - 1);
      return;
    }

    if (emailF.hasFocus) {
      final len = emailC.text.length.clamp(0, 30);
      setState(() => look = (len / 30) * 2 - 1);
      return;
    }
  }

  void _syncMascot() {
    setState(() {
      eyesClosed = passF.hasFocus && !showPassword;
    });
    _updateMascotLookFromActiveField();
  }

  @override
  void dispose() {
    userC.dispose();
    emailC.dispose();
    passC.dispose();
    userF.dispose();
    emailF.dispose();
    passF.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signupEmail() async {
    setState(() => loading = true);
    try {
      if (userC.text.trim().isEmpty) {
        _toast("Username is required.");
        return;
      }
      await AuthService.instance.signUpWithEmail(
        email: emailC.text,
        password: passC.text,
        username: userC.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AuthGate.route, (r) => false);
    } catch (e) {
      _toast(authErrorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signupGoogle() async {
    setState(() => loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AuthGate.route, (r) => false);
    } catch (e) {
      _toast(authErrorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signupApple() async {
    setState(() => loading = true);
    try {
      await AuthService.instance.signInWithApple();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AuthGate.route, (r) => false);
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
                      "Create account",
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
                              onPressed: loading ? () {} : _signupApple,
                            ),
                            const SizedBox(height: 10),
                          ],
                          GoogleButton(
                            onPressed: loading ? () {} : _signupGoogle,
                          ),
                          const SizedBox(height: 14),
                          const OrDivider(),
                          const SizedBox(height: 14),

                          AuthField(
                            label: "Username",
                            icon: Icons.person_outline,
                            controller: userC,
                            focusNode: userF,
                          ),
                          const SizedBox(height: 12),

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
                            ],
                          ),

                          const SizedBox(height: 12),
                          PrimaryCTA(
                            text: "SIGN UP",
                            onPressed: _signupEmail,
                            loading: loading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Sign in"),
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
