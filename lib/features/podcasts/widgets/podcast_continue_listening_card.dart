import 'package:flutter/material.dart';

class PodcastContinueListeningCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? category;
  final bool isYouTube;
  final Widget thumbnail; // your image widget
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const PodcastContinueListeningCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.thumbnail,
    required this.onOpen,
    required this.onDismiss,
    this.category,
    this.isYouTube = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE6E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 54, height: 54, child: thumbnail),
          ),
          const SizedBox(width: 12),

          /// ✅ This must be Expanded so it never overflows
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ✅ chips must not wrap into multiple lines
                SizedBox(
                  height: 28,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _pill(
                          icon: Icons.play_circle_fill_rounded,
                          text: isYouTube ? 'Continue video' : 'Continue',
                          bg: const Color(0xFFEAF7EF),
                          fg: const Color(0xFF1C7D3A),
                        ),
                        if ((category ?? '').trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _pill(
                            icon: Icons.sell_rounded,
                            text: category!.trim(),
                            bg: const Color(0xFFF3EDFF),
                            fg: const Color(0xFF5A40C8),
                          ),
                        ],
                        if (isYouTube) ...[
                          const SizedBox(width: 8),
                          _pill(
                            icon: Icons.ondemand_video_rounded,
                            text: 'YouTube',
                            bg: const Color(0xFFFFEAEA),
                            fg: const Color(0xFFB42318),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1, // ✅ prevents overflow
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B6B6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          /// ✅ Actions are in their own column so X never sits “before Open”
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text('Open'),
                ),
              ),
              const SizedBox(height: 6),
              Material(
                color: const Color(0xFFF3F3F3),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDismiss,
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String podcastWhen(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
