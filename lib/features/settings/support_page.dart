import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/premium_settings.dart';
import '../../core/legal_links.dart';
import '../../ui/app_theme.dart';
import 'account_settings_page.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _openEmail(BuildContext context) async {
    if (!LegalLinks.hasSupportEmail) return;

    final uri = Uri(
      scheme: 'mailto',
      path: LegalLinks.supportEmail,
      queryParameters: const {'subject': 'Pettounsi support request'},
    );

    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      await Clipboard.setData(ClipboardData(text: LegalLinks.supportEmail));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open your mail app. Email copied.'),
        ),
      );
    }
  }

  Future<void> _openExternalUrl(
    BuildContext context,
    String url,
    String label,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $label.')));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $label. Link copied.')),
      );
    }
  }

  Future<void> _copyText(
    BuildContext context,
    String text,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyPublicContact =
        LegalLinks.hasSupportEmail ||
        LegalLinks.hasPrivacyPolicyUrl ||
        LegalLinks.hasTermsUrl;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Support & contact')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          PremiumSettingsHero(
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(235),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF4C79C8),
                size: 28,
              ),
            ),
            title: 'We’re here to help',
            subtitle:
                'Find support options, review privacy information, or manage your account requests.',
          ),
          const SizedBox(height: 12),

          if (LegalLinks.hasSupportEmail)
            _Section(
              title: 'Contact',
              icon: Icons.mail_outline_rounded,
              iconBg: AppTheme.sky,
              iconFg: const Color(0xFF4C79C8),
              children: [
                _ActionTile(
                  title: 'Email support',
                  subtitle: LegalLinks.supportEmail,
                  icon: Icons.send_rounded,
                  tint: const Color(0xFF4C79C8),
                  bg: AppTheme.sky,
                  onTap: () => _openEmail(context),
                  trailingLabel: 'Open',
                ),
                _ActionTile(
                  title: 'Copy support email',
                  subtitle: 'Use this if your mail app does not open',
                  icon: Icons.copy_rounded,
                  tint: const Color(0xFF7C62D7),
                  bg: AppTheme.lilac,
                  onTap: () => _copyText(
                    context,
                    LegalLinks.supportEmail,
                    'Support email',
                  ),
                  trailingLabel: 'Copy',
                ),
              ],
            ),

          if (LegalLinks.hasSupportEmail) const SizedBox(height: 12),

          if (LegalLinks.hasPrivacyPolicyUrl || LegalLinks.hasTermsUrl)
            _Section(
              title: 'Privacy & legal',
              icon: Icons.privacy_tip_rounded,
              iconBg: AppTheme.mint,
              iconFg: const Color(0xFF2F9A6A),
              children: [
                if (LegalLinks.hasPrivacyPolicyUrl)
                  _ActionTile(
                    title: 'Privacy policy',
                    subtitle: 'Open the public privacy policy page',
                    icon: Icons.shield_outlined,
                    tint: const Color(0xFF2F9A6A),
                    bg: AppTheme.mint,
                    onTap: () => _openExternalUrl(
                      context,
                      LegalLinks.privacyPolicyUrl,
                      'privacy policy',
                    ),
                    trailingLabel: 'Open',
                  ),
                if (LegalLinks.hasPrivacyPolicyUrl)
                  _ActionTile(
                    title: 'Copy privacy policy link',
                    subtitle: LegalLinks.privacyPolicyUrl,
                    icon: Icons.link_rounded,
                    tint: const Color(0xFF2F9A6A),
                    bg: AppTheme.mint,
                    onTap: () => _copyText(
                      context,
                      LegalLinks.privacyPolicyUrl,
                      'Privacy policy link',
                    ),
                    trailingLabel: 'Copy',
                  ),
                if (LegalLinks.hasTermsUrl)
                  _ActionTile(
                    title: 'Terms of use',
                    subtitle: 'Open the public terms page',
                    icon: Icons.article_outlined,
                    tint: const Color(0xFFDA8A1F),
                    bg: const Color(0xFFFFF2DB),
                    onTap: () =>
                        _openExternalUrl(context, LegalLinks.termsUrl, 'terms'),
                    trailingLabel: 'Open',
                  ),
                if (LegalLinks.hasTermsUrl)
                  _ActionTile(
                    title: 'Copy terms link',
                    subtitle: LegalLinks.termsUrl,
                    icon: Icons.copy_all_rounded,
                    tint: const Color(0xFFDA8A1F),
                    bg: const Color(0xFFFFF2DB),
                    onTap: () =>
                        _copyText(context, LegalLinks.termsUrl, 'Terms link'),
                    trailingLabel: 'Copy',
                  ),
              ],
            ),

          if (LegalLinks.hasPrivacyPolicyUrl || LegalLinks.hasTermsUrl)
            const SizedBox(height: 12),

          _Section(
            title: 'Account help',
            icon: Icons.manage_accounts_rounded,
            iconBg: const Color(0xFFFFEBEB),
            iconFg: const Color(0xFFE05555),
            children: [
              _ActionTile(
                title: 'Request account deletion',
                subtitle: 'Open the in-app deletion request flow',
                icon: Icons.delete_forever_rounded,
                tint: const Color(0xFFE05555),
                bg: const Color(0xFFFFEBEB),
                onTap: () => _push(context, const AccountSettingsPage()),
                trailingLabel: 'Open',
              ),
              if (LegalLinks.hasAccountDeletionUrl)
                _ActionTile(
                  title: 'Public account deletion page',
                  subtitle: 'Open the web page used for store deletion compliance',
                  icon: Icons.language_rounded,
                  tint: const Color(0xFFE05555),
                  bg: const Color(0xFFFFEBEB),
                  onTap: () => _openExternalUrl(
                    context,
                    LegalLinks.accountDeletionUrl,
                    'account deletion page',
                  ),
                  trailingLabel: 'Open',
                ),
              if (LegalLinks.hasAccountDeletionUrl)
                _ActionTile(
                  title: 'Copy deletion page link',
                  subtitle: LegalLinks.accountDeletionUrl,
                  icon: Icons.link_rounded,
                  tint: const Color(0xFFE05555),
                  bg: const Color(0xFFFFEBEB),
                  onTap: () => _copyText(
                    context,
                    LegalLinks.accountDeletionUrl,
                    'Deletion page link',
                  ),
                  trailingLabel: 'Copy',
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  'For account deletion, privacy requests, or abusive content reports, include your account email, device type, and a short description so we can help you faster.',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),

          if (!hasAnyPublicContact) ...[
            const SizedBox(height: 12),
            const PremiumSettingsInfoCard(
              title: 'Support details unavailable',
              subtitle:
                  'Support details are currently unavailable in this build.',
              icon: Icons.info_outline_rounded,
              iconBg: AppTheme.sky,
              iconFg: Color(0xFF4C79C8),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsSectionCard(
      title: title,
      subtitle: '',
      icon: icon,
      iconBg: iconBg,
      iconFg: iconFg,
      children: children,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.bg,
    required this.onTap,
    required this.trailingLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Color bg;
  final VoidCallback onTap;
  final String trailingLabel;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsNavTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      tint: tint,
      bg: bg,
      onTap: onTap,
      trailingLabel: trailingLabel,
    );
  }
}
