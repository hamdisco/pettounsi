import 'package:flutter/material.dart';

import '../services/connectivity_status_controller.dart';
import 'app_theme.dart';

class OfflineBannerOverlay extends StatelessWidget {
  const OfflineBannerOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ConnectivityStatusController.instance,
      builder: (context, _) {
        final offline = ConnectivityStatusController.instance.isOffline;

        return Stack(
          children: [
            child,
            Positioned(
              left: 12,
              right: 12,
              top: 0,
              child: IgnorePointer(
                ignoring: !offline,
                child: SafeArea(
                  bottom: false,
                  child: AnimatedSlide(
                    offset: offline ? Offset.zero : const Offset(0, -1.2),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: offline ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: _OfflineBanner(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Separate widget so it has its own BuildContext for Theme.of().
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          // Uses theme surface — works in both light and dark mode
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline),
          boxShadow: AppTheme.softShadows(0.18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // lilac tint works in both modes; icon color is constant
                color: AppTheme.lilac,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFF6B56C9),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You are offline',
                    style: TextStyle(
                      // Uses theme onSurface — adapts to dark/light
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.6,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Saved content will still appear when available.',
                    style: TextStyle(
                      // Uses onSurfaceVariant for secondary text
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.6,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () =>
                  ConnectivityStatusController.instance.refresh(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B56C9),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
