import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import '../babysitting_repository.dart';

class TrustRow extends StatelessWidget {
  const TrustRow({super.key, required this.listing});

  final BabysittingListing listing;

  String _ago(DateTime? d) {
    final dt = d ?? listing.createdAt;
    if (dt == null) return 'Recent';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = listing.authorPhotoUrl.trim().isNotEmpty;
    final busyCount = listing.unavailableDateKeys.length + listing.bookedDateKeys.length;
    final updated = _ago(listing.updatedAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
        color: Colors.white,
        boxShadow: AppTheme.softShadows(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trust signals',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TrustTile(
                  icon: hasPhoto ? Icons.account_circle_rounded : Icons.person_outline_rounded,
                  title: hasPhoto ? 'Profile photo' : 'Basic profile',
                  subtitle: hasPhoto ? 'Visible' : 'Ask for details',
                  bg: AppTheme.sky,
                  fg: const Color(0xFF4C79C8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StreamBuilder<BabysitterRatingSummary>(
                  stream: BabysittingRepository.instance.streamListingRatingSummary(
                    listing.id,
                    limit: 250,
                  ),
                  builder: (context, snap) {
                    final s = snap.data ?? BabysitterRatingSummary.empty;
                    return _TrustTile(
                      icon: Icons.star_rounded,
                      title: s.count == 0 ? 'New sitter' : '${s.average.toStringAsFixed(1)} ★',
                      subtitle: s.count == 0 ? 'No stays yet' : '${s.count} review${s.count == 1 ? '' : 's'}',
                      bg: AppTheme.butter,
                      fg: const Color(0xFFB96B00),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TrustTile(
                  icon: Icons.event_available_rounded,
                  title: busyCount == 0 ? 'Open dates' : '$busyCount busy',
                  subtitle: 'Calendar check',
                  bg: busyCount >= 8 ? AppTheme.butter : AppTheme.mint,
                  fg: busyCount >= 8 ? const Color(0xFF8A5A00) : const Color(0xFF2F9A6A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrustTile(
                  icon: Icons.update_rounded,
                  title: updated,
                  subtitle: 'Last update',
                  bg: AppTheme.lilac,
                  fg: AppTheme.orchidDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _TrustNote(
            icon: Icons.chat_bubble_outline_rounded,
            text: 'Chat before booking to confirm routine, price, pickup/drop-off, and emergency details.',
          ),
        ],
      ),
    );
  }
}

class _TrustTile extends StatelessWidget {
  const _TrustTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(220),
              fontWeight: FontWeight.w800,
              fontSize: 10.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.orangeDark),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(175),
              fontWeight: FontWeight.w700,
              fontSize: 12.3,
              height: 1.28,
            ),
          ),
        ),
      ],
    );
  }
}
