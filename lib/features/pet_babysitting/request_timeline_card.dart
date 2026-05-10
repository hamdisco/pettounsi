import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/user_avatar.dart';
import '../messages/chat_page.dart';
import 'babysitting_repository.dart';
import 'babysitting_sheets.dart';

const Color _petPrimary = AppTheme.orangeDark;
const Color _petPrimarySoft = Color(0xFFFFF3EE);
const Color _petTrust = Color(0xFF2F9A6A);
const Color _petInfo = Color(0xFF4C79C8);
const Color _petNeutralChip = Color(0xFFF8F5FA);

String? _requestMomentLabel(DateTime? value) {
  if (value == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  final diff = today.difference(date).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '${diff}d ago';
  if (diff < 30) return '${(diff / 7).floor()}w ago';
  return '${value.day}/${value.month}/${value.year}';
}

class RequestsHeaderBar extends StatelessWidget {
  const RequestsHeaderBar({
    super.key,
    required this.incomingCount,
    required this.sentCount,
    required this.segment,
    required this.onSegmentChanged,
  });

  final int incomingCount;
  final int sentCount;
  final int segment;
  final ValueChanged<int> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    final total = incomingCount + sentCount;

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      shadowOpacity: 0.07,
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _petPrimarySoft,
                  border: Border.all(color: AppTheme.outline.withAlpha(160)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.inbox_rounded,
                  color: _petPrimary,
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
                      'Bookings, replies, and completed stays.',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
          const SizedBox(height: 12),
          _SegmentedWithBadges(
            leftLabel: 'Incoming',
            leftCount: incomingCount,
            rightLabel: 'Sent',
            rightCount: sentCount,
            value: segment,
            onChanged: onSegmentChanged,
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
                    color: selected ? _petPrimary : AppTheme.ink,
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
                  color: selected ? _petPrimarySoft : AppTheme.bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? _petPrimary
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


class RequestsStatusFilterBar extends StatelessWidget {
  const RequestsStatusFilterBar({
    super.key,
    required this.value,
    required this.allCount,
    required this.pendingCount,
    required this.acceptedCount,
    required this.completedCount,
    required this.closedCount,
    required this.onChanged,
  });

  final String value;
  final int allCount;
  final int pendingCount;
  final int acceptedCount;
  final int completedCount;
  final int closedCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <_RequestFilterData>[
      _RequestFilterData(
        key: 'all',
        label: 'All',
        count: allCount,
        icon: Icons.list_rounded,
      ),
      _RequestFilterData(
        key: 'pending',
        label: 'Pending',
        count: pendingCount,
        icon: Icons.hourglass_bottom_rounded,
      ),
      _RequestFilterData(
        key: 'accepted',
        label: 'Confirmed',
        count: acceptedCount,
        icon: Icons.check_circle_rounded,
      ),
      _RequestFilterData(
        key: 'completed',
        label: 'Done',
        count: completedCount,
        icon: Icons.verified_rounded,
      ),
      _RequestFilterData(
        key: 'closed',
        label: 'Closed',
        count: closedCount,
        icon: Icons.archive_rounded,
      ),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = value == filter.key;
          return _RequestFilterChip(
            data: filter,
            selected: selected,
            onTap: () => onChanged(filter.key),
          );
        },
      ),
    );
  }
}

class _RequestFilterData {
  const _RequestFilterData({
    required this.key,
    required this.label,
    required this.count,
    required this.icon,
  });

  final String key;
  final String label;
  final int count;
  final IconData icon;
}

class _RequestFilterChip extends StatelessWidget {
  const _RequestFilterChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _RequestFilterData data;
  final bool selected;
  final VoidCallback onTap;

  Color get _fg {
    if (selected) return AppTheme.orangeDark;
    return AppTheme.ink.withAlpha(190);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF2EC) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppTheme.orangeDark.withAlpha(110) : AppTheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 15, color: _fg),
              const SizedBox(width: 7),
              Text(
                data.label,
                style: TextStyle(
                  color: _fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.8,
                  height: 1,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppTheme.bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  '${data.count}',
                  style: TextStyle(
                    color: _fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.8,
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
          bg: _petPrimarySoft,
          fg: _petPrimary,
          accent: _petPrimary,
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
            ? 'Everything is wrapped up and the stay has ended.'
            : 'This booking is finished and ready for follow-up.',
      );
    }
    if (req.isAccepted) {
      return const _StatePanelData(
        title: 'Booking confirmed',
        subtitle: 'The dates are locked in and chat stays open.',
      );
    }
    if (req.isDeclined) {
      return _StatePanelData(
        title: 'Request declined',
        subtitle: incoming
            ? 'You declined this request.'
            : 'This sitter could not take the booking.',
      );
    }
    if (req.isCanceled) {
      return const _StatePanelData(
        title: 'Request canceled',
        subtitle: 'The booking was canceled before confirmation.',
      );
    }
    return _StatePanelData(
      title: incoming ? 'Awaiting your reply' : 'Waiting for a reply',
      subtitle: incoming
          ? 'Review the stay details and reply when ready.'
          : 'Your booking request has been sent successfully.',
    );
  }

  String _peerUid() => incoming ? req.requesterId : req.listingOwnerId;
  String _peerName() => incoming ? req.requesterName : req.listingOwnerName;
  String _peerPhoto() => incoming ? req.requesterPhotoUrl : '';
  String _toplineLabel() =>
      incoming ? 'Requested your listing' : 'Sent to sitter';

  @override
  Widget build(BuildContext context) {
    final style = _style();
    final panel = _panel();
    final momentLabel = _requestMomentLabel(req.updatedAt ?? req.createdAt);

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      shadowOpacity: 0.055,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                uid: _peerUid(),
                radius: 23,
                fallbackName: _peerName(),
                fallbackPhotoUrl: _peerPhoto(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserName(
                      uid: _peerUid(),
                      fallback: _peerName().trim().isEmpty
                          ? 'PetTounsi user'
                          : _peerName().trim(),
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _toplineLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _petPrimary.withAlpha(214),
                        fontWeight: FontWeight.w800,
                        fontSize: 11.3,
                        height: 1,
                      ),
                    ),
                    if (req.listingTitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        req.listingTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(220),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.2,
                          height: 1.08,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(style: style),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RequestMetaChip(
                icon: Icons.calendar_today_rounded,
                text: req.dateRangeText,
                bg: const Color(0xFFF1F7FF),
                fg: _petInfo,
              ),
              if (momentLabel != null)
                _RequestMetaChip(
                  icon: Icons.schedule_rounded,
                  text: momentLabel,
                  bg: _petNeutralChip,
                  fg: AppTheme.ink,
                ),
              if (req.conversationId.trim().isNotEmpty && !req.isPending)
                _RequestMetaChip(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'Chat ready',
                  bg: const Color(0xFFF3FBF7),
                  fg: _petTrust,
                ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 13),
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
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: style.bg.withAlpha(190)),
                ),
                alignment: Alignment.center,
                child: Icon(style.icon, size: 18, color: style.fg),
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
                        fontSize: 14.2,
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
                        fontSize: 11.4,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StageRail(status: status),
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

class _StageRail extends StatelessWidget {
  const _StageRail({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages(status);
    return Row(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          Expanded(child: _StageNode(stage: stages[i])),
          if (i < stages.length - 1)
            Expanded(
              child: _StageConnector(left: stages[i], right: stages[i + 1]),
            ),
        ],
      ],
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

class _StageNode extends StatelessWidget {
  const _StageNode({required this.stage});

  final _StageData stage;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final Color border;

    switch (stage.state) {
      case _StageVisual.complete:
        bg = stage.color;
        fg = Colors.white;
        border = stage.color;
        break;
      case _StageVisual.current:
        bg = stage.color.withAlpha(30);
        fg = stage.color;
        border = stage.color.withAlpha(120);
        break;
      case _StageVisual.idle:
        bg = Colors.white;
        fg = AppTheme.muted.withAlpha(185);
        border = AppTheme.outline;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Icon(stage.icon, size: 15, color: fg),
        ),
        const SizedBox(height: 7),
        Text(
          stage.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: stage.state == _StageVisual.idle
                ? AppTheme.muted.withAlpha(180)
                : AppTheme.ink,
            fontWeight: FontWeight.w800,
            fontSize: 10.6,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _StageConnector extends StatelessWidget {
  const _StageConnector({required this.left, required this.right});

  final _StageData left;
  final _StageData right;

  @override
  Widget build(BuildContext context) {
    final active =
        left.state != _StageVisual.idle && right.state != _StageVisual.idle;
    return Align(
      alignment: const Alignment(0, -0.48),
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: active ? left.color.withAlpha(120) : AppTheme.outline,
          borderRadius: BorderRadius.circular(99),
        ),
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
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outline),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.format_quote_rounded,
              size: 17,
              color: AppTheme.orchidDark.withAlpha(220),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(188),
                    fontWeight: FontWeight.w800,
                    fontSize: 10.8,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(188),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    height: 1.22,
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

    Future<bool> confirmAction({
      required String title,
      required String body,
      required String actionLabel,
      Color actionColor = AppTheme.orangeDark,
    }) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: actionColor),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(actionLabel),
              ),
            ],
          );
        },
      );

      return result == true;
    }

    void showTrustSnack(String message) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Future<void> decline() async {
      final ok = await confirmAction(
        title: 'Decline this request?',
        body:
            'The pet owner will be notified. Decline only when the dates, price, or care routine cannot work for you.',
        actionLabel: 'Decline request',
        actionColor: const Color(0xFFE05555),
      );
      if (!ok) return;

      try {
        await BabysittingRepository.instance.declineRequest(req);
        showTrustSnack('Request declined. The owner was notified kindly.');
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decline request: $e')),
        );
      }
    }

    Future<void> accept() async {
      final ok = await confirmAction(
        title: 'Accept this stay?',
        body:
            'The selected dates will be reserved on your sitter calendar. Use chat next to confirm handoff, routine, emergency contact, and final price.',
        actionLabel: 'Accept stay',
        actionColor: const Color(0xFF2F9A6A),
      );
      if (!ok) return;

      try {
        await BabysittingRepository.instance.acceptRequestAndBlockDates(req);
        showTrustSnack('Stay accepted. Dates are reserved — confirm final details in chat.');
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not accept request: $e')));
      }
    }

    Future<void> cancel() async {
      final ok = await confirmAction(
        title: req.isAccepted ? 'Cancel confirmed stay?' : 'Cancel request?',
        body: req.isAccepted
            ? 'The sitter will be notified and the reserved dates will be released again.'
            : 'The sitter will be notified that you no longer need this stay.',
        actionLabel: req.isAccepted ? 'Cancel stay' : 'Cancel request',
        actionColor: const Color(0xFFE05555),
      );
      if (!ok) return;

      try {
        await BabysittingRepository.instance.cancelRequest(req);
        showTrustSnack(req.isAccepted
            ? 'Confirmed stay canceled. The sitter was notified and dates were released.'
            : 'Request canceled. The sitter was notified.');
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not cancel request: $e')));
      }
    }

    Future<void> complete() async {
      final ok = await confirmAction(
        title: 'Mark stay completed?',
        body:
            'Only do this after the stay is finished and the pet has been returned safely. The owner will be invited to leave a review.',
        actionLabel: 'Mark completed',
        actionColor: const Color(0xFF3357D6),
      );
      if (!ok) return;

      try {
        await BabysittingRepository.instance.completeRequest(req);
        showTrustSnack('Stay completed. The owner can now leave a review.');
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
              label: 'Accept stay',
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
      if (!incoming) {
        if (canChat) {
          return Row(
            children: [
              Expanded(
                child: _GhostActionButton(
                  onPressed: openChat,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _PassiveStatusPill(
                  icon: Icons.verified_rounded,
                  label: 'Confirmed',
                ),
              ),
            ],
          );
        }

        return const _SingleActionRow(
          child: _PassiveStatusPill(
            icon: Icons.verified_rounded,
            label: 'Confirmed',
          ),
        );
      }

      if (canChat) {
        return Row(
          children: [
            Expanded(
              child: _GhostActionButton(
                onPressed: openChat,
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrimaryActionButton(
                onPressed: complete,
                icon: Icons.check_rounded,
                label: 'Mark done',
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
          label: 'Mark done',
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
                label: 'Message',
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

class _PassiveStatusPill extends StatelessWidget {
  const _PassiveStatusPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FFF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2F9A6A).withAlpha(90)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF2F9A6A)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2F9A6A),
                fontWeight: FontWeight.w900,
                fontSize: 12.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleActionRow extends StatelessWidget {
  const _SingleActionRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Expanded(child: child)]);
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
