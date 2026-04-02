import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/user_avatar.dart';
import '../messages/chat_page.dart';
import 'babysitting_repository.dart';
import 'babysitting_sheets.dart';

class RequestsHeaderBar extends StatelessWidget {
  const RequestsHeaderBar({
    super.key,
    required this.incomingCount,
    required this.sentCount,
    required this.segment,
    required this.onSegmentChanged,
    this.incomingPending = 0,
    this.sentActive = 0,
    this.completedCount = 0,
  });

  final int incomingCount;
  final int sentCount;
  final int incomingPending;
  final int sentActive;
  final int completedCount;
  final int segment;
  final ValueChanged<int> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    final total = incomingCount + sentCount;

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      shadowOpacity: 0.07,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.orchidDark, AppTheme.roseDark],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.inbox_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requests',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Incoming and sent bookings.',
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(208),
                        fontWeight: FontWeight.w700,
                        fontSize: 10.9,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.mist,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  '$total total',
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(188),
                    fontWeight: FontWeight.w900,
                    fontSize: 11.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SegmentedWithBadges(
            leftLabel: 'Incoming',
            leftCount: incomingCount,
            rightLabel: 'Sent',
            rightCount: sentCount,
            value: segment,
            onChanged: onSegmentChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CompactMetricChip(
                  label: 'Pending',
                  value: '$incomingPending',
                  bg: const Color(0xFFFFF3DE),
                  fg: const Color(0xFFDA8A1F),
                  icon: Icons.hourglass_bottom_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactMetricChip(
                  label: 'Active',
                  value: '$sentActive',
                  bg: AppTheme.mint,
                  fg: const Color(0xFF2F9A6A),
                  icon: Icons.pets_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactMetricChip(
                  label: 'Done',
                  value: '$completedCount',
                  bg: AppTheme.sky,
                  fg: const Color(0xFF4C79C8),
                  icon: Icons.verified_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactMetricChip extends StatelessWidget {
  const _CompactMetricChip({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  final String label;
  final String value;
  final Color bg;
  final Color fg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 13, color: fg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(190),
                    fontWeight: FontWeight.w800,
                    fontSize: 10.6,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedWithBadges extends StatelessWidget {
  const _SegmentedWithBadges({
    required this.leftLabel,
    required this.leftCount,
    required this.rightLabel,
    required this.rightCount,
    required this.value,
    required this.onChanged,
  });

  final String leftLabel;
  final int leftCount;
  final String rightLabel;
  final int rightCount;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegBtn(
              label: leftLabel,
              count: leftCount,
              selected: value == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegBtn(
              label: rightLabel,
              count: rightCount,
              selected: value == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppTheme.orchidDark : AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.8,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.lilac : AppTheme.bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? AppTheme.orchidDark
                        : AppTheme.ink.withAlpha(190),
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    height: 1,
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

class RequestsTimelineCard extends StatelessWidget {
  const RequestsTimelineCard({
    super.key,
    required this.req,
    required this.incoming,
  });

  final BabysittingRequestModel req;
  final bool incoming;

  _StatusStyle _style() {
    switch (req.status) {
      case 'accepted':
        return const _StatusStyle(
          bg: Color(0xFFE9FFF5),
          fg: Color(0xFF2F9A6A),
          accent: Color(0xFF2F9A6A),
          icon: Icons.check_circle_rounded,
          label: 'Accepted',
        );
      case 'declined':
        return const _StatusStyle(
          bg: Color(0xFFFFEBEB),
          fg: Color(0xFFE05555),
          accent: Color(0xFFE05555),
          icon: Icons.cancel_rounded,
          label: 'Declined',
        );
      case 'completed':
        return const _StatusStyle(
          bg: Color(0xFFEAF2FF),
          fg: Color(0xFF3357D6),
          accent: Color(0xFF3357D6),
          icon: Icons.verified_rounded,
          label: 'Completed',
        );
      case 'canceled':
        return const _StatusStyle(
          bg: Color(0xFFF2F2F2),
          fg: Color(0xFF757575),
          accent: Color(0xFF8A8A8A),
          icon: Icons.remove_circle_rounded,
          label: 'Canceled',
        );
      default:
        return const _StatusStyle(
          bg: AppTheme.mist,
          fg: AppTheme.orchidDark,
          accent: AppTheme.orchidDark,
          icon: Icons.hourglass_bottom_rounded,
          label: 'Pending',
        );
    }
  }

  _StatePanelData _panel() {
    if (req.isCompleted) {
      return _StatePanelData(
        title: 'Stay completed',
        subtitle: incoming
            ? 'The booking ended successfully.'
            : 'The stay is finished and ready for follow-up.',
      );
    }
    if (req.isAccepted) {
      return const _StatePanelData(
        title: 'Booking confirmed',
        subtitle: 'Dates are locked and chat is available.',
      );
    }
    if (req.isDeclined) {
      return _StatePanelData(
        title: 'Request declined',
        subtitle: incoming
            ? 'You declined this request.'
            : 'The sitter could not take this booking.',
      );
    }
    if (req.isCanceled) {
      return const _StatePanelData(
        title: 'Request canceled',
        subtitle: 'This booking request was canceled before confirmation.',
      );
    }
    return _StatePanelData(
      title: incoming ? 'Waiting for your response' : 'Waiting for sitter response',
      subtitle: incoming
          ? 'Review the request and decide whether to accept it.'
          : 'Your request is sent and still awaiting confirmation.',
    );
  }

  String _peerUid() => incoming ? req.requesterId : req.listingOwnerId;
  String _peerName() => incoming ? req.requesterName : req.listingOwnerName;
  String _peerPhoto() => incoming ? req.requesterPhotoUrl : '';

  @override
  Widget build(BuildContext context) {
    final style = _style();
    final panel = _panel();

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      shadowOpacity: 0.07,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                uid: _peerUid(),
                radius: 22,
                fallbackName: _peerName(),
                fallbackPhotoUrl: _peerPhoto(),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _peerName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.3,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      req.listingTitle.trim().isEmpty
                          ? (incoming ? 'Incoming request' : 'Sent request')
                          : req.listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(220),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.0,
                        height: 1.08,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(style: style),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RequestMetaChip(
                icon: Icons.calendar_today_rounded,
                text: req.dateRangeText,
                bg: AppTheme.sky,
                fg: const Color(0xFF4C79C8),
              ),
              _RequestMetaChip(
                icon: incoming
                    ? Icons.call_received_rounded
                    : Icons.call_made_rounded,
                text: incoming ? 'Incoming' : 'Sent',
                bg: AppTheme.lilac,
                fg: AppTheme.orchidDark,
              ),
            ],
          ),
          const SizedBox(height: 11),
          _RequestStateBlock(
            style: style,
            title: panel.title,
            subtitle: panel.subtitle,
            status: req.status,
          ),
          if (req.message.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _MessageSnippet(text: req.message),
          ],
          const SizedBox(height: 12),
          _Actions(req: req, incoming: incoming),
        ],
      ),
    );
  }
}

class _RequestMetaChip extends StatelessWidget {
  const _RequestMetaChip({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.3,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestStateBlock extends StatelessWidget {
  const _RequestStateBlock({
    required this.style,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final _StatusStyle style;
  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: style.bg.withAlpha(78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.bg.withAlpha(160)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: style.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
                alignment: Alignment.center,
                child: Icon(style.icon, size: 16, color: style.fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.9,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(206),
                        fontWeight: FontWeight.w700,
                        fontSize: 11.2,
                        height: 1.16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StageFlow(status: status),
        ],
      ),
    );
  }
}

class _StatePanelData {
  const _StatePanelData({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _StageFlow extends StatelessWidget {
  const _StageFlow({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages(status);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stages.map((stage) => _StageChip(stage: stage)).toList(),
    );
  }

  List<_StageData> _buildStages(String status) {
    const requestedColor = AppTheme.orchidDark;
    const acceptedColor = Color(0xFF2F9A6A);
    const completedColor = Color(0xFF3357D6);
    const declinedColor = Color(0xFFE05555);
    const canceledColor = Color(0xFF8A8A8A);

    if (status == 'declined') {
      return const [
        _StageData(
          label: 'Requested',
          icon: Icons.check_rounded,
          color: requestedColor,
          state: _StageVisual.complete,
        ),
        _StageData(
          label: 'Declined',
          icon: Icons.close_rounded,
          color: declinedColor,
          state: _StageVisual.current,
        ),
      ];
    }

    if (status == 'canceled') {
      return const [
        _StageData(
          label: 'Requested',
          icon: Icons.check_rounded,
          color: requestedColor,
          state: _StageVisual.complete,
        ),
        _StageData(
          label: 'Canceled',
          icon: Icons.remove_rounded,
          color: canceledColor,
          state: _StageVisual.current,
        ),
      ];
    }

    if (status == 'completed') {
      return const [
        _StageData(
          label: 'Requested',
          icon: Icons.check_rounded,
          color: requestedColor,
          state: _StageVisual.complete,
        ),
        _StageData(
          label: 'Accepted',
          icon: Icons.check_rounded,
          color: acceptedColor,
          state: _StageVisual.complete,
        ),
        _StageData(
          label: 'Done',
          icon: Icons.check_rounded,
          color: completedColor,
          state: _StageVisual.complete,
        ),
      ];
    }

    if (status == 'accepted') {
      return const [
        _StageData(
          label: 'Requested',
          icon: Icons.check_rounded,
          color: requestedColor,
          state: _StageVisual.complete,
        ),
        _StageData(
          label: 'Accepted',
          icon: Icons.check_rounded,
          color: acceptedColor,
          state: _StageVisual.current,
        ),
        _StageData(
          label: 'Done',
          icon: Icons.flag_rounded,
          color: completedColor,
          state: _StageVisual.idle,
        ),
      ];
    }

    return const [
      _StageData(
        label: 'Requested',
        icon: Icons.schedule_rounded,
        color: requestedColor,
        state: _StageVisual.current,
      ),
      _StageData(
        label: 'Accepted',
        icon: Icons.check_rounded,
        color: acceptedColor,
        state: _StageVisual.idle,
      ),
      _StageData(
        label: 'Done',
        icon: Icons.flag_rounded,
        color: completedColor,
        state: _StageVisual.idle,
      ),
    ];
  }
}

enum _StageVisual { complete, current, idle }

class _StageData {
  const _StageData({
    required this.label,
    required this.icon,
    required this.color,
    required this.state,
  });

  final String label;
  final IconData icon;
  final Color color;
  final _StageVisual state;
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.stage});

  final _StageData stage;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final Color border;

    switch (stage.state) {
      case _StageVisual.complete:
        bg = stage.color.withAlpha(28);
        fg = stage.color;
        border = stage.color.withAlpha(80);
        break;
      case _StageVisual.current:
        bg = stage.color.withAlpha(36);
        fg = stage.color;
        border = stage.color.withAlpha(118);
        break;
      case _StageVisual.idle:
        bg = Colors.white;
        fg = AppTheme.muted.withAlpha(185);
        border = AppTheme.outline;
        break;
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stage.icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(
            stage.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 10.7,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageSnippet extends StatelessWidget {
  const _MessageSnippet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outline),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: AppTheme.orchidDark.withAlpha(220),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(186),
                fontWeight: FontWeight.w800,
                fontSize: 12.4,
                height: 1.16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.bg,
    required this.fg,
    required this.accent,
    required this.icon,
    required this.label,
  });

  final Color bg;
  final Color fg;
  final Color accent;
  final IconData icon;
  final String label;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.style});
  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return PremiumCardBadge(
      label: style.label,
      icon: style.icon,
      bg: style.bg,
      fg: style.fg,
      borderColor: AppTheme.outline,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      fontSize: 11.4,
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.req, required this.incoming});
  final BabysittingRequestModel req;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final canChat = req.conversationId.trim().isNotEmpty;

    Future<void> openChat() async {
      if (!canChat) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            otherUid: incoming ? req.requesterId : req.listingOwnerId,
            otherName: incoming ? req.requesterName : req.listingOwnerName,
            otherPhoto: incoming
                ? (req.requesterPhotoUrl.trim().isEmpty
                    ? null
                    : req.requesterPhotoUrl)
                : null,
          ),
        ),
      );
    }

    Future<void> decline() async {
      try {
        await BabysittingRepository.instance.declineRequest(req);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decline request: $e')),
        );
      }
    }

    Future<void> accept() async {
      try {
        await BabysittingRepository.instance.acceptRequestAndBlockDates(req);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not accept request: $e')),
        );
      }
    }

    Future<void> cancel() async {
      try {
        await BabysittingRepository.instance.cancelRequest(req);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel request: $e')),
        );
      }
    }

    Future<void> complete() async {
      try {
        await BabysittingRepository.instance.completeRequest(req);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not complete request: $e')),
        );
      }
    }

    if (incoming && req.isPending) {
      return Row(
        children: [
          Expanded(
            child: _GhostActionButton(
              onPressed: decline,
              icon: Icons.close_rounded,
              label: 'Decline',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PrimaryActionButton(
              onPressed: accept,
              icon: Icons.check_rounded,
              label: 'Accept',
              background: const Color(0xFF2F9A6A),
            ),
          ),
        ],
      );
    }

    if (!incoming && req.isPending) {
      return _SingleActionRow(
        child: _GhostActionButton(
          onPressed: cancel,
          icon: Icons.close_rounded,
          label: 'Cancel request',
        ),
      );
    }

    if (req.isAccepted) {
      if (canChat) {
        return Row(
          children: [
            Expanded(
              child: _GhostActionButton(
                onPressed: openChat,
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrimaryActionButton(
                onPressed: complete,
                icon: Icons.check_rounded,
                label: 'Complete',
                background: const Color(0xFF3357D6),
              ),
            ),
          ],
        );
      }

      return _SingleActionRow(
        child: _PrimaryActionButton(
          onPressed: complete,
          icon: Icons.check_rounded,
          label: 'Complete',
          background: const Color(0xFF3357D6),
        ),
      );
    }

    if (!incoming && req.isCompleted) {
      return Row(
        children: [
          if (canChat)
            Expanded(
              child: _GhostActionButton(
                onPressed: openChat,
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
              ),
            ),
          if (canChat) const SizedBox(width: 10),
          Expanded(
            child: StreamBuilder<bool>(
              stream: BabysittingRepository.instance.streamHasReviewedRequest(
                req.id,
              ),
              builder: (context, snap) {
                final done = snap.data ?? false;
                return _PrimaryActionButton(
                  onPressed: done
                      ? null
                      : () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => LeaveReviewSheet(req: req),
                          );
                        },
                  icon: Icons.rate_review_rounded,
                  label: done ? 'Reviewed' : 'Leave review',
                  background: AppTheme.orchidDark,
                );
              },
            ),
          ),
        ],
      );
    }

    if (canChat) {
      return _SingleActionRow(
        child: _GhostActionButton(
          onPressed: openChat,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _SingleActionRow extends StatelessWidget {
  const _SingleActionRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Expanded(child: child)],
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.ink,
          side: const BorderSide(color: AppTheme.outline),
          backgroundColor: AppTheme.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.background,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: AppTheme.outline,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppTheme.muted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
