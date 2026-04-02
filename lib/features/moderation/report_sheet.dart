import 'package:flutter/material.dart';
import '../../repositories/reports_repository.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_pills.dart';
import '../../ui/premium_sheet.dart';

class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.type, // 'post' or 'user'
    this.postId,
    required this.targetUid,
  });

  final String type;
  final String? postId;
  final String targetUid;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _details = TextEditingController();
  bool _loading = false;
  String? _reason;

  static const _reasons = <String>[
    "Spam",
    "Harassment",
    "Hate / Abuse",
    "Scam / Fraud",
    "Adult content",
    "Violence",
    "Other",
  ];

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _loading = true);
    try {
      if (widget.type == 'post') {
        await ReportsRepository.instance.reportPost(
          postId: widget.postId!,
          targetUid: widget.targetUid,
          reason: _reason!,
          details: _details.text,
        );
      } else {
        await ReportsRepository.instance.reportUser(
          targetUid: widget.targetUid,
          reason: _reason!,
          details: _details.text,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thanks. Your report was submitted.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetFrame(
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFFE05555),
      iconBg: const Color(0xFFFFEBEB),
      title: widget.type == 'post' ? 'Report post' : 'Report user',
      subtitle:
          'Tell us what is wrong so we can review this content more safely.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason',
            style: TextStyle(
              color: AppTheme.ink.withAlpha(170),
              fontWeight: FontWeight.w900,
              fontSize: 12.6,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.map((r) {
              final selected = _reason == r;
              return PremiumPill(
                label: r,
                selected: selected,
                onTap: _loading ? null : () => setState(() => _reason = r),
                showCheckWhenSelected: true,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Optional details',
              hintText: 'Add context to help the review.',
              prefixIcon: Icon(Icons.notes_rounded),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          const PremiumSheetInfoCard(
            icon: Icons.privacy_tip_rounded,
            iconBg: AppTheme.sky,
            iconFg: Color(0xFF4C79C8),
            title: 'Your report stays private',
            subtitle:
                'Only the moderation side should use this information for review.',
            compact: true,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_reason == null || _loading) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orangeDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Submit report',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
