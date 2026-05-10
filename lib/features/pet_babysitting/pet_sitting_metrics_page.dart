import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import 'pet_sitting_metrics_service.dart';

class PetSittingMetricsPage extends StatelessWidget {
  const PetSittingMetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Pet Sitting metrics'),
        backgroundColor: AppTheme.bg,
        elevation: 0,
      ),
      body: StreamBuilder<PetSittingMetricsSummary>(
        stream: PetSittingMetricsService.instance.streamSummary(),
        builder: (context, snapshot) {
          final metrics = snapshot.data ?? PetSittingMetricsSummary.empty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.outline),
                  boxShadow: AppTheme.softShadows(0.08),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Investor-ready Pet Sitting signals',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Lightweight counters collected from real app actions. No Cloud Functions required.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  _MetricCard(
                    label: 'Sitter profiles',
                    value: metrics.listingCreatedCount.toString(),
                    subtitle: 'created listings',
                    icon: Icons.person_search_rounded,
                    accent: const Color(0xFFFF6A4B),
                    bg: const Color(0xFFFFEFE8),
                  ),
                  _MetricCard(
                    label: 'Requests',
                    value: metrics.requestCreatedCount.toString(),
                    subtitle: 'booking intent',
                    icon: Icons.assignment_rounded,
                    accent: const Color(0xFF7C62D7),
                    bg: const Color(0xFFF1ECFF),
                  ),
                  _MetricCard(
                    label: 'Confirmed',
                    value: metrics.requestAcceptedCount.toString(),
                    subtitle: 'accepted stays',
                    icon: Icons.verified_rounded,
                    accent: const Color(0xFF2BA56E),
                    bg: const Color(0xFFEAF8F0),
                  ),
                  _MetricCard(
                    label: 'Completed',
                    value: metrics.stayCompletedCount.toString(),
                    subtitle: 'finished stays',
                    icon: Icons.flag_rounded,
                    accent: const Color(0xFFF0B127),
                    bg: const Color(0xFFFFF7E7),
                  ),
                  _MetricCard(
                    label: 'Reviews',
                    value: metrics.reviewCount.toString(),
                    subtitle: metrics.reviewCount == 0
                        ? 'not enough yet'
                        : '${metrics.averageRating.toStringAsFixed(1)} average',
                    icon: Icons.star_rounded,
                    accent: const Color(0xFFE26E96),
                    bg: const Color(0xFFFFEEF4),
                  ),
                  _MetricCard(
                    label: 'Closed',
                    value:
                        '${metrics.requestDeclinedCount + metrics.requestCanceledCount}',
                    subtitle: 'declined/canceled',
                    icon: Icons.cancel_rounded,
                    accent: const Color(0xFF5F6573),
                    bg: const Color(0xFFF3F4F7),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What these numbers prove',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InsightRow(
                      label: 'Demand',
                      value: '${metrics.requestCreatedCount} requests sent',
                    ),
                    _InsightRow(
                      label: 'Supply',
                      value: '${metrics.listingCreatedCount} sitter profiles created',
                    ),
                    _InsightRow(
                      label: 'Trust',
                      value: '${metrics.reviewCount} reviews published',
                    ),
                    _InsightRow(
                      label: 'Conversion',
                      value:
                          '${metrics.requestAcceptedCount} confirmed / ${metrics.stayCompletedCount} completed',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.bg,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
