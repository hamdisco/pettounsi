import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import 'models/podcast_episode.dart';
import 'podcast_player_page.dart';
import 'services/podcast_resume_store.dart';
import 'services/podcasts_repository.dart';
import 'widgets/podcast_ui.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/premium_sheet.dart';

class PodcastsPage extends StatefulWidget {
  const PodcastsPage({super.key});

  @override
  State<PodcastsPage> createState() => _PodcastsPageState();
}

class _PodcastsPageState extends State<PodcastsPage> {
  final _repo = const PodcastsRepository();
  final _searchCtrl = TextEditingController();

  String _q = '';
  String _selectedCategory = 'All';
  late Future<PodcastResume?> _resumeFuture;

  @override
  void initState() {
    super.initState();
    _resumeFuture = PodcastResume.readLast();
    _searchCtrl.addListener(() {
      // Keep suffix icon reactive.
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshResume() async {
    final next = PodcastResume.readLast();
    if (!mounted) return;
    setState(() => _resumeFuture = next);
  }

  Future<void> _openEpisode(PodcastEpisode episode) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PodcastPlayerPage(episode: episode)),
    );
    await _refreshResume();
  }

  Future<void> _openResume(PodcastResume r) async {
    final episode = PodcastEpisode(
      id: r.episodeId,
      title: r.title,
      description: r.description,
      audioUrl: r.audioUrl,
      category: r.category,
      isPublished: true,
      coverImageUrl: r.imageUrl,
      durationLabel: r.durationLabel,
      youtubeUrl: r.youtubeUrl,
      sourceType: r.sourceType,
      videoId: r.videoId,
      publishedAt: null,
    );

    await _openEpisode(episode);
  }

  void _showInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const PremiumBottomSheetFrame(
          icon: Icons.podcasts_rounded,
          iconColor: Color(0xFF4C79C8),
          iconBg: AppTheme.sky,
          title: 'Podcasts',
          subtitle: 'Short, helpful episodes curated for pet lovers.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumSheetInfoCard(
                icon: Icons.touch_app_rounded,
                iconBg: AppTheme.lilac,
                iconFg: Color(0xFF7C62D7),
                title: 'Open any episode',
                subtitle:
                    'Tap a podcast card to start listening or watching immediately.',
              ),
              SizedBox(height: 10),
              PremiumSheetInfoCard(
                icon: Icons.search_rounded,
                iconBg: AppTheme.blush,
                iconFg: AppTheme.orangeDark,
                title: 'Search and filter',
                subtitle:
                    'Use search and categories to find the right episode faster.',
              ),
              SizedBox(height: 10),
              PremiumSheetInfoCard(
                icon: Icons.history_rounded,
                iconBg: AppTheme.mint,
                iconFg: Color(0xFF2F9A6A),
                title: 'Continue listening',
                subtitle:
                    'Your latest episode position is saved so you can continue later.',
              ),
              SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showAppBar = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: showAppBar
          ? AppBar(
              title: const Text('Podcasts'),
              backgroundColor: AppTheme.bg,
              foregroundColor: AppTheme.ink,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        top: !showAppBar,
        child: StreamBuilder<List<PodcastEpisode>>(
          stream: _repo.watchPublished(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(14),
                child: _ErrorCard(
                  title: 'Podcasts query needs an index',
                  subtitle:
                      'Create a composite index for: podcasts → isPublished + publishedAt(desc).',
                ),
              );
            }

            final episodes = snap.data ?? const <PodcastEpisode>[];
            final categories = _buildCategories(episodes);

            final q = _q.trim().toLowerCase();
            final filtered = episodes.where((e) {
              final matchesSearch =
                  q.isEmpty ||
                  e.title.toLowerCase().contains(q) ||
                  e.description.toLowerCase().contains(q) ||
                  e.category.toLowerCase().contains(q);
              final matchesCategory =
                  _selectedCategory == 'All' || e.category == _selectedCategory;
              return matchesSearch && matchesCategory;
            }).toList();

            final featured = episodes.take(8).toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  sliver: SliverToBoxAdapter(
                    child: PodcastHeroHeader(onTapInfo: _showInfo),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  sliver: SliverToBoxAdapter(
                    child: FutureBuilder<PodcastResume?>(
                      future: _resumeFuture,
                      builder: (context, rs) {
                        final resume = rs.data;
                        if (resume == null) return const SizedBox.shrink();

                        return ContinueListeningCard(
                          resume: resume,
                          onOpen: () => _openResume(resume),
                          onClear: () async {
                            await PodcastResume.clearLast();
                            await _refreshResume();
                          },
                        );
                      },
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  sliver: SliverToBoxAdapter(
                    child: PodcastSearchField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _q = v),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _q = '');
                      },
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  sliver: SliverToBoxAdapter(
                    child: CategoryChips(
                      categories: categories,
                      selected: _selectedCategory,
                      onSelect: (c) => setState(() => _selectedCategory = c),
                    ),
                  ),
                ),

                if (featured.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                    sliver: SliverToBoxAdapter(
                      child: const SectionHeader(
                        title: 'Featured',
                        subtitle: 'Quick picks to start listening',
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 170,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final e = featured[i];
                          return PodcastFeaturedCard(
                            episode: e,
                            onTap: () => _openEpisode(e),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'All episodes',
                      subtitle: snap.connectionState == ConnectionState.waiting
                          ? 'Loading…'
                          : '${filtered.length} episode${filtered.length == 1 ? '' : 's'}',
                      trailing: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _q = '';
                            _selectedCategory = 'All';
                            _searchCtrl.clear();
                          });
                        },
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Reset'),
                      ),
                    ),
                  ),
                ),

                if (snap.connectionState == ConnectionState.waiting &&
                    episodes.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 30),
                    sliver: SliverToBoxAdapter(child: _LoadingList()),
                  )
                else if (filtered.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 30),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyCard(
                        title: 'No matches',
                        subtitle:
                            'Try a different search or choose another category.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 26),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        return PodcastEpisodeCard(
                          episode: e,
                          onTap: () => _openEpisode(e),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<String> _buildCategories(List<PodcastEpisode> episodes) {
  final set = <String>{'All'};
  for (final e in episodes) {
    final c = e.category.trim();
    if (c.isNotEmpty) set.add(c);
  }
  final list = set.toList();
  list.sort((a, b) {
    if (a == 'All') return -1;
    if (b == 'All') return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  });
  return list;
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE05555),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyStateCard(
      icon: Icons.search_off_rounded,
      iconColor: const Color(0xFF4C79C8),
      iconBg: AppTheme.sky,
      title: title,
      subtitle: subtitle,
      compact: true,
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumSkeletonCard(
            height: 120,
            radius: 26,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [AppTheme.lilac, AppTheme.sky],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      PremiumSkeletonLine(width: 90, height: 12),
                      SizedBox(height: 12),
                      PremiumSkeletonLine(width: double.infinity, height: 16),
                      SizedBox(height: 10),
                      PremiumSkeletonLine(width: 180, height: 14),
                      Spacer(),
                      PremiumSkeletonLine(width: 74, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
