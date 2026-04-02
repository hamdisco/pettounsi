import 'package:flutter/material.dart';

import '../core/url_utils.dart';
import '../services/user_mini_cache.dart';
import 'app_theme.dart';

String _initial(String name) {
  final t = name.trim();
  if (t.isEmpty) return 'U';
  // Avoid crashing on emoji/empty
  return t.characters.first.toUpperCase();
}

class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.uid,
    this.radius = 18,
    this.fallbackName = 'User',
    this.fallbackPhotoUrl,
    this.onTap,
  });

  final String uid;
  final double radius;
  final String fallbackName;
  final String? fallbackPhotoUrl;
  final VoidCallback? onTap;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  int _bust = 0;
  int _retryCount = 0;

  Widget _placeholder(String name) {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.lilac,
      ),
      alignment: Alignment.center,
      child: Text(
        _initial(name),
        style: TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w900,
          fontSize: widget.radius * 0.9,
          height: 1.0,
        ),
      ),
    );
  }

  String _cacheBustedUrl(String url) {
    final safe = Uri.encodeFull(UrlUtils.normalizeMediaUrl(url));
    if (safe.isEmpty) return '';
    final sep = safe.contains('?') ? '&' : '?';
    return '$safe${sep}cb=$_bust';
  }

  Widget _image(String url, String name) {
    final u = _cacheBustedUrl(url);
    if (u.isEmpty) return _placeholder(name);

    return ClipOval(
      child: Image.network(
        u,
        width: widget.radius * 2,
        height: widget.radius * 2,
        fit: BoxFit.cover,
        // Some OEM stacks/hosts are picky; a UA header improves reliability.
        headers: const {'User-Agent': 'Mozilla/5.0'},
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) {
          // Retry a couple times in case of transient failures
          if (_retryCount < 2) {
            _retryCount += 1;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _bust += 1);
            });
          }
          return _placeholder(name);
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = UserMiniCache.instance.stream(widget.uid);

    final base = StreamBuilder<UserMini?>(
      key: ValueKey('userAvatar_${widget.uid}'),
      stream: stream,
      initialData: UserMiniCache.instance.peek(widget.uid),
      builder: (context, snap) {
        final mini = snap.data;

        final name = (mini?.name.trim().isNotEmpty == true)
            ? mini!.name
            : widget.fallbackName;

        final photo = (mini?.photoUrl.trim().isNotEmpty == true)
            ? mini!.photoUrl
            : ((widget.fallbackPhotoUrl ?? '').trim().isNotEmpty
                ? widget.fallbackPhotoUrl
                : null);

        final avatar = (photo == null) ? _placeholder(name) : _image(photo, name);

        return Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.outline, width: 1),
            boxShadow: AppTheme.softShadows(0.16),
          ),
          child: avatar,
        );
      },
    );

    if (widget.onTap == null) return base;

    return InkWell(
      onTap: widget.onTap,
      customBorder: const CircleBorder(),
      child: base,
    );
  }
}

class UserName extends StatelessWidget {
  const UserName({
    super.key,
    required this.uid,
    this.fallback = 'User',
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String uid;
  final String fallback;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserMini?>(
      key: ValueKey('userName_$uid'),
      stream: UserMiniCache.instance.stream(uid),
      initialData: UserMiniCache.instance.peek(uid),
      builder: (context, snap) {
        final name = (snap.data?.name.trim().isNotEmpty == true) ? snap.data!.name : fallback;
        return Text(
          name,
          maxLines: maxLines,
          overflow: overflow,
          style: style,
        );
      },
    );
  }
}
