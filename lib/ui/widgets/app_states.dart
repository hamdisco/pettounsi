import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Reusable loading / empty / error UI states for pages and sections.
/// Firestore note:
/// - This file does NOT read/write Firestore.
/// - It is meant to be used by Firestore-backed pages for cleaner UI code.

class AppPageLoading extends StatelessWidget {
  const AppPageLoading({
    super.key,
    this.message,
    this.padding = const EdgeInsets.all(20),
  });

  final String? message;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if ((message ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                message!.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppEmptyStateCard extends StatelessWidget {
  const AppEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.maxWidth = 420,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasAction = (actionLabel ?? '').trim().isNotEmpty && onAction != null;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 14 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 18 : 22),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 54 : 62,
                  height: compact ? 54 : 62,
                  decoration: BoxDecoration(
                    color: AppTheme.softOrange.withAlpha(90),
                    borderRadius: BorderRadius.circular(compact ? 16 : 18),
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 26 : 30,
                    color: AppTheme.orangeDark,
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 15 : 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasAction) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel!.trim()),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppErrorStateCard extends StatelessWidget {
  const AppErrorStateCard({
    super.key,
    this.title = 'Something went wrong',
    required this.errorText,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.maxWidth = 440,
    this.compact = false,
    this.showRawError = true,
  });

  final String title;
  final String errorText;
  final VoidCallback? onRetry;
  final String retryLabel;
  final double maxWidth;
  final bool compact;
  final bool showRawError;

  @override
  Widget build(BuildContext context) {
    final safeError = errorText.trim().isEmpty
        ? 'Unknown error'
        : errorText.trim();

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 14 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 18 : 22),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 54 : 62,
                  height: compact ? 54 : 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(compact ? 16 : 18),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 30,
                    color: Color(0xFFD85050),
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 15 : 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showRawError) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Text(
                      safeError,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: compact ? 3 : 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(retryLabel),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppInlineMessage extends StatelessWidget {
  const AppInlineMessage({
    super.key,
    required this.icon,
    required this.text,
    this.isWarning = false,
  });

  final IconData icon;
  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final bg = isWarning ? const Color(0xFFFFF8EE) : const Color(0xFFF7F9FC);
    final iconColor = isWarning ? AppTheme.orangeDark : AppTheme.muted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(210),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppRetryButton extends StatelessWidget {
  const AppRetryButton({
    super.key,
    required this.onPressed,
    this.label = 'Retry',
    this.fullWidth = false,
    this.icon = Icons.refresh_rounded,
  });

  final VoidCallback onPressed;
  final String label;
  final bool fullWidth;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: fullWidth ? const Size.fromHeight(42) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    if (!fullWidth) return btn;

    return SizedBox(width: double.infinity, child: btn);
  }
}
