import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';

String _safeMediaUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) return '';
  if (url.startsWith('//')) url = 'https:$url';
  if (url.startsWith('http://')) url = 'https://${url.substring(7)}';
  url = url.replaceAll(' ', '%20');

  if (url.contains('res.cloudinary.com') && url.contains('/image/upload/')) {
    final split = url.split('/image/upload/');
    if (split.length == 2) {
      final prefix = split[0];
      final rest = split[1];
      if (!(rest.startsWith('f_') || rest.startsWith('q_') || rest.startsWith('c_'))) {
        url = '$prefix/image/upload/f_jpg,q_auto/$rest';
      }
    }
  }

  try {
    url = Uri.encodeFull(url);
  } catch (_) {}

  return url;
}

class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({super.key, required this.urls, this.initialIndex = 0});
  final List<String> urls;
  final int initialIndex;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late final PageController _c = PageController(
    initialPage: widget.initialIndex.clamp(0, (widget.urls.length - 1).clamp(0, 999999)),
  );
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _i = widget.initialIndex.clamp(0, (widget.urls.length - 1).clamp(0, 999999));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.urls.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _c,
            onPageChanged: (v) => setState(() => _i = v),
            itemCount: total,
            itemBuilder: (_, idx) {
              final u = _safeMediaUrl(widget.urls[idx]);

              final widgetImage = kReleaseMode
                  ? Image.network(
                      u,
                      fit: BoxFit.contain,
                      headers: const {'User-Agent': 'Mozilla/5.0'},
                      errorBuilder: (context, error, stack) {
                        debugPrint('[IMG_FAIL][viewer] $u -> $error');
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 32,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: AppTheme.orange,
                          ),
                        );
                      },
                    )
                  : CachedNetworkImage(
                      imageUrl: u,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: AppTheme.orange,
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    );

              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(child: widgetImage),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Text(
                      '${_i + 1} / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
