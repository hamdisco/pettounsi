import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/store_compliance.dart';
import '../../ui/app_theme.dart';
import '../../services/first_steps_guide_service.dart';
import '../onboarding/first_steps_guide.dart';
import '../settings/legal_page.dart';
import '../settings/support_page.dart';

class _ComplianceGateSession {
  static final Set<String> runningForUser = <String>{};
  static final Set<String> acceptedThisSession = <String>{};
}

class ComplianceGate extends StatefulWidget {
  const ComplianceGate({super.key, required this.child});

  final Widget child;

  @override
  State<ComplianceGate> createState() => _ComplianceGateState();
}

class _ComplianceGateState extends State<ComplianceGate> {
  bool _checking = false;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _needsAcceptance(Map<String, dynamic> data) {
    final version = (data['communityPolicyVersion'] ?? '').toString().trim();
    final communityAccepted =
        _readDate(data['communityPolicyAcceptedAt']) != null;
    final privacyAccepted = _readDate(data['privacyPolicyAcceptedAt']) != null;
    final termsAccepted = _readDate(data['termsAcceptedAt']) != null;

    return version != StoreCompliance.currentPolicyVersion ||
        !communityAccepted ||
        !privacyAccepted ||
        !termsAccepted;
  }

  Future<void> _maybePrompt() async {
    if (!mounted || _checking || _sheetOpen) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_ComplianceGateSession.runningForUser.contains(user.uid)) return;

    _ComplianceGateSession.runningForUser.add(user.uid);
    _checking = true;
    try {
      final skipComplianceForSession = _ComplianceGateSession
          .acceptedThisSession
          .contains(user.uid);

      if (!skipComplianceForSession) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = snap.data() ?? <String, dynamic>{};
        if (_needsAcceptance(data) && mounted) {
          _sheetOpen = true;
          await showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            enableDrag: false,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const FractionallySizedBox(
              heightFactor: 0.94,
              child: _ComplianceSheet(),
            ),
          );
          _sheetOpen = false;
        }
      }

      await _maybeShowFirstStepsGuide();
    } finally {
      _checking = false;
      _ComplianceGateSession.runningForUser.remove(user.uid);
    }
  }

  Future<void> _maybeShowFirstStepsGuide() async {
    if (!mounted || _sheetOpen) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final shouldShow = await FirstStepsGuideService.instance.shouldShowForUser(
      user.uid,
    );
    if (!shouldShow || !mounted) return;

    _sheetOpen = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const FirstStepsGuidePage(),
        ),
      );
      await FirstStepsGuideService.instance.markShownForUser(user.uid);
    } finally {
      _sheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ComplianceSheet extends StatefulWidget {
  const _ComplianceSheet();

  @override
  State<_ComplianceSheet> createState() => _ComplianceSheetState();
}

class _ComplianceSheetState extends State<_ComplianceSheet> {
  bool _acceptCommunity = false;
  bool _acceptPrivacy = false;
  bool _busy = false;
  bool _showValidation = false;

  Future<void> _accept() async {
    final valid = _acceptCommunity && _acceptPrivacy;
    if (!valid) {
      setState(() => _showValidation = true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'communityPolicyAcceptedAt': FieldValue.serverTimestamp(),
        'privacyPolicyAcceptedAt': FieldValue.serverTimestamp(),
        'termsAcceptedAt': FieldValue.serverTimestamp(),
        'communityPolicyVersion': StoreCompliance.currentPolicyVersion,
        'communityPolicySource': 'mandatory_gate',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _ComplianceGateSession.acceptedThisSession.add(user.uid);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your acknowledgment. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openLegalPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LegalPage()));
  }

  void _openSupportPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SupportPage()));
  }

  void _onCommunityChanged(bool value) {
    setState(() {
      _acceptCommunity = value;
      if (_showValidation && _acceptCommunity && _acceptPrivacy) {
        _showValidation = false;
      }
    });
  }

  void _onPrivacyChanged(bool value) {
    setState(() {
      _acceptPrivacy = value;
      if (_showValidation && _acceptCommunity && _acceptPrivacy) {
        _showValidation = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeaderBlock(),
                    const SizedBox(height: 16),
                    _OpenCard(
                      icon: Icons.menu_book_rounded,
                      title: 'Terms & community rules',
                      subtitle:
                          'Review what is allowed across posts, comments, chats, reports, and listings.',
                      onTap: _busy ? null : _openLegalPage,
                    ),
                    const SizedBox(height: 10),
                    _OpenCard(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy, support & account deletion',
                      subtitle:
                          'See how data is handled, where support is available, and how account deletion requests are processed.',
                      onTap: _busy ? null : _openSupportPage,
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle('Key rules'),
                    const SizedBox(height: 10),
                    _ChipCard(items: StoreCompliance.prohibitedContent),
                    const SizedBox(height: 16),
                    const _SectionTitle('What to know'),
                    const SizedBox(height: 10),
                    _InfoCard(items: StoreCompliance.privacyHighlights),
                    const SizedBox(height: 18),
                    const _SectionTitle('Confirm to continue'),
                    const SizedBox(height: 10),
                    _CheckRow(
                      value: _acceptCommunity,
                      hasError: _showValidation && !_acceptCommunity,
                      enabled: !_busy,
                      title: 'I reviewed the terms and community rules.',
                      onChanged: _onCommunityChanged,
                    ),
                    const SizedBox(height: 10),
                    _CheckRow(
                      value: _acceptPrivacy,
                      hasError: _showValidation && !_acceptPrivacy,
                      enabled: !_busy,
                      title:
                          'I reviewed the privacy, support, and account deletion information.',
                      onChanged: _onPrivacyChanged,
                    ),
                    if (_showValidation &&
                        (!_acceptCommunity || !_acceptPrivacy)) ...[
                      const SizedBox(height: 10),
                      const _InlineError(
                        'Check both confirmations to continue.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _BottomActionBar(busy: _busy, onPressed: _accept),
          ],
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outline),
                boxShadow: AppTheme.softShadows(0.03),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppTheme.orchidDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community rules & privacy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review the details below to continue.',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: AppTheme.outline.withAlpha(150)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.ink,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.1,
      ),
    );
  }
}

class _OpenCard extends StatelessWidget {
  const _OpenCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.035),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.mist,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 24, color: AppTheme.orchidDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.muted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD8D8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE05555),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == items.length - 1 ? 0 : 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF2F9A6A),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.value,
    required this.hasError,
    required this.enabled,
    required this.title,
    required this.onChanged,
  });

  final bool value;
  final bool hasError;
  final bool enabled;
  final String title;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFE05555)
        : value
        ? AppTheme.orchidDark
        : AppTheme.outline;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: value || hasError ? 1.4 : 1,
            ),
            boxShadow: value ? AppTheme.softShadows(0.03) : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: value ? AppTheme.orchidDark : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasError
                        ? const Color(0xFFE05555)
                        : value
                        ? AppTheme.orchidDark
                        : AppTheme.muted.withAlpha(105),
                    width: 1.6,
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD8D8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE05555),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB44242),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: busy ? null : onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : const Text('Accept and continue'),
          ),
        ),
      ),
    );
  }
}
