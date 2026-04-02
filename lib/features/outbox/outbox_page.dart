import 'package:flutter/material.dart';

import '../../services/post_outbox_service.dart';
import '../../ui/app_theme.dart';

class OutboxPage extends StatelessWidget {
  const OutboxPage({super.key});

  String _relative(DateTime dt) {
    final now = DateTime.now();
    final d = dt.difference(now);
    if (d.inSeconds <= 0) return 'now';
    if (d.inSeconds < 60) return 'in ${d.inSeconds}s';
    if (d.inMinutes < 60) return 'in ${d.inMinutes}m';
    if (d.inHours < 24) return 'in ${d.inHours}h';
    return 'in ${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final svc = PostOutboxService.instance;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: const Text(
          'Outbox',
          style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: AppTheme.ink),
        actions: [
          IconButton(
            tooltip: 'Retry all now',
            onPressed: () => svc.processQueue(force: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<PostOutboxItem>>(
        valueListenable: svc.items,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(245),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.outline),
                        boxShadow: AppTheme.softShadows(0.25),
                      ),
                      child: const Icon(
                        Icons.outbox_rounded,
                        size: 42,
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All caught up!',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "If a post can't be published (offline), it will be saved here and retried automatically.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(220),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = items[i];
              final next = it.nextAttemptAt;
              final ready = it.readyToSend;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(248),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.outline),
                  boxShadow: AppTheme.softShadows(0.22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: ready ? AppTheme.softOrange : AppTheme.bg,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Text(
                              ready
                                  ? 'Ready to retry'
                                  : 'Retry ${_relative(next)}',
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (it.attemptCount > 0)
                            Text(
                              'Attempts: ${it.attemptCount}',
                              style: TextStyle(
                                color: AppTheme.muted.withAlpha(220),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          const Spacer(),
                          if (it.localImagePaths.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.bg,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Text(
                                '${it.localImagePaths.length} photo${it.localImagePaths.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: AppTheme.muted.withAlpha(230),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        it.text.isEmpty ? '(No text)' : it.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      if (it.lastError.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          it.lastError,
                          style: TextStyle(
                            color: AppTheme.muted.withAlpha(230),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => svc.retryNow(it.id),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  title: const Text('Delete draft?'),
                                  content: const Text(
                                    'This will remove the saved post from Outbox.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await svc.remove(it.id);
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFE05555),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
