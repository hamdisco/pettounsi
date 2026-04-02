import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../ui/premium_sheet.dart';
import '../../core/auth_error_text.dart';
import '../../services/auth_service.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_settings.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _auth = FirebaseAuth.instance;

  bool _sendingReset = false;
  DateTime? _lastResetSentAt;

  User? get _user => _auth.currentUser;

  bool get _hasPasswordProvider {
    final u = _user;
    if (u == null) return false;
    return u.providerData.any((p) => p.providerId == 'password');
  }

  Future<void> _sendReset({bool force = false}) async {
    final u = _user;
    final email = (u?.email ?? '').trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found for this account')),
      );
      return;
    }

    // Throttle resends (prevents spam taps)
    final now = DateTime.now();
    if (!force && _lastResetSentAt != null) {
      final delta = now.difference(_lastResetSentAt!);
      if (delta.inSeconds < 30) {
        final wait = 30 - delta.inSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please wait ${wait}s before resending')),
        );
        return;
      }
    }

    setState(() => _sendingReset = true);
    try {
      await AuthService.instance.sendPasswordReset(email);
      _lastResetSentAt = now;
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorText(e))));
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _openChangePassword() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    final email = (u?.email ?? '').trim();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          _Card(
            title: 'Password',
            icon: Icons.lock_rounded,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            child: Column(
              children: [
                _ActionRow(
                  title: 'Change password',
                  subtitle: _hasPasswordProvider
                      ? 'Update your password securely'
                      : 'This account does not use a password',
                  icon: Icons.key_rounded,
                  tint: const Color(0xFF2F9A6A),
                  onTap: (!_hasPasswordProvider) ? null : _openChangePassword,
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  title: 'Send reset email',
                  subtitle: email.isEmpty
                      ? 'Email account required'
                      : 'Send to $email',
                  icon: Icons.mail_outline_rounded,
                  tint: const Color(0xFF2F9A6A),
                  onTap: (_sendingReset || !_hasPasswordProvider)
                      ? null
                      : () => _sendReset(force: true),
                ),
                if (!_hasPasswordProvider) ...[
                  const SizedBox(height: 10),
                  _Info(
                    text:
                        'This account uses a social sign-in method. Password changes need to be managed through that sign-in provider.',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Reset email link looks broken?',
            icon: Icons.help_outline_rounded,
            iconBg: AppTheme.sky,
            iconFg: const Color(0xFF4C79C8),
            child: const _Info(
              text:
                  'If the reset link does not open correctly, try opening the email in Gmail or in your browser.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorText(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetFrame(
      icon: Icons.key_rounded,
      iconColor: const Color(0xFF2F9A6A),
      iconBg: AppTheme.mint,
      title: 'Change password',
      subtitle: 'Update your password securely for this account.',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: !_showCurrent,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Current password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _showCurrent = !_showCurrent),
                  icon: Icon(
                    _showCurrent
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Enter your current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              obscureText: !_showNext,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _showNext = !_showNext),
                  icon: Icon(
                    _showNext
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a new password';
                if (v.length < 6) return 'Use at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: !_showConfirm,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _showConfirm = !_showConfirm),
                  icon: Icon(
                    _showConfirm
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Confirm your new password';
                }
                if (v != _next.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 12),
            const PremiumSheetInfoCard(
              icon: Icons.privacy_tip_rounded,
              iconBg: AppTheme.sky,
              iconFg: Color(0xFF4C79C8),
              title: 'Security tip',
              subtitle:
                  'Use a strong password you do not reuse in other apps or websites.',
              compact: true,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: const Text('Update password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsSectionCard(
      title: title,
      subtitle: '',
      icon: icon,
      iconBg: iconBg,
      iconFg: iconFg,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      children: [child],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsNavTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      tint: tint,
      bg: tint.withAlpha(24),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsInfoCard(
      title: 'Helpful note',
      subtitle: text,
      icon: Icons.info_outline_rounded,
      iconBg: AppTheme.sky,
      iconFg: const Color(0xFF4C79C8),
    );
  }
}
