import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import '../babysitting_repository.dart';

class TrustRow extends StatelessWidget {
  const TrustRow({super.key, required this.listing});

  final BabysittingListing listing;

  String _ago(DateTime? d) {
    final dt = d ?? listing.createdAt;
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = listing.authorPhotoUrl.trim().isNotEmpty;
    final updated = _ago(listing.updatedAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
        color: Colors.white,
        boxShadow: AppTheme.softShadows(0.10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TrustTile(
              icon: hasPhoto ? Icons.verified_rounded : Icons.person_rounded,
              title: hasPhoto ? 'Profile photo' : 'Profile',
              subtitle: hasPhoto ? 'Added' : 'Basic',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StreamBuilder<BabysitterRatingSummary>(
              stream: BabysittingRepository.instance.streamListingRatingSummary(listing.id, limit: 250),
              builder: (context, snap) {
                final s = snap.data ?? BabysitterRatingSummary.empty;
                final title = s.count == 0 ? 'Reviews' : '${s.average.toStringAsFixed(1)} ★';
                final sub = s.count == 0 ? 'New' : '${s.count} total';

                return _TrustTile(
                  icon: Icons.star_rounded,
                  title: title,
                  subtitle: sub,
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TrustTile(
              icon: Icons.update_rounded,
              title: 'Updated',
              subtitle: updated,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: _TrustTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chat',
              subtitle: 'Available',
            ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.orangeDark),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
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
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
