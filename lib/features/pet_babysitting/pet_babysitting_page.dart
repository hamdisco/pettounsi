import 'dart:async';
import '../../ui/premium_pills.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../ui/premium_page_header.dart';
import '../../ui/app_theme.dart';
import '../../ui/user_avatar.dart';
import '../messages/chat_page.dart';
import 'babysitting_repository.dart';
import 'babysitting_sheets.dart';
import 'create_babysitting_listing_sheet.dart';
import 'listing_details_page.dart';
import 'request_timeline_card.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';

class PetBabysittingPage extends StatefulWidget {
  const PetBabysittingPage({super.key});

  @override
  State<PetBabysittingPage> createState() => _PetBabysittingPageState();
}

class _PetBabysittingPageState extends State<PetBabysittingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      if (_tab != _tabs.index) {
        setState(() => _tab = _tabs.index);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openNewListing() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateBabysittingListingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.bg,
            foregroundColor: AppTheme.ink,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 66,
            collapsedHeight: 66,
            titleSpacing: 16,
            title: const Text(
              'Pet Sitting',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.2,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: _PremiumTabs(controller: _tabs),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _BrowseTab(myUid: me?.uid ?? '', onCreateListing: _openNewListing),
            const _MyListingsTab(),
            const _RequestsTab(),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [AppTheme.orchidDark, AppTheme.roseDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppTheme.softShadows(0.18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumTabs extends StatelessWidget {
  const _PremiumTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.07),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(14),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: [AppTheme.orchidDark, AppTheme.roseDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.orchidDark.withAlpha(24),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.ink.withAlpha(176),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11.2,
          height: 1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11.0,
          height: 1,
        ),
        tabs: const [
          Tab(height: 36, text: 'Browse'),
          Tab(height: 36, text: 'My listings'),
          Tab(height: 36, text: 'Requests'),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, size: 20, color: fg),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(220),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.6,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================
// Browse
// ======================================================

class _BrowseTab extends StatefulWidget {
  const _BrowseTab({required this.myUid, required this.onCreateListing});

  final String myUid;
  final VoidCallback onCreateListing;

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  final _q = TextEditingController();
  Timer? _debounce;

  String _query = '';
  String _pet = 'Any';
  String _availability = 'Any';
  String _sort = 'Newest';

  int get _activeFiltersCount {
    var c = 0;
    if (_pet != 'Any') c++;
    if (_availability != 'Any') c++;
    return c;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _query = v.trim().toLowerCase());
    });
  }

  Future<void> _openFilters() async {
    final res = await showModalBottomSheet<_FilterValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _FiltersSheet(initialPet: _pet, initialAvailability: _availability),
    );

    if (!mounted || res == null) return;
    setState(() {
      _pet = res.pet;
      _availability = res.availability;
    });
  }

  Future<void> _openSort() async {
    final res = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        value: _sort,
        values: const ['Newest', 'Price ↑', 'Price ↓'],
      ),
    );

    if (!mounted || res == null) return;
    setState(() => _sort = res);
  }

  void _resetFilters() {
    setState(() {
      _pet = 'Any';
      _availability = 'Any';
    });
  }

  bool _availabilityOk(BabysittingListing l) {
    if (_availability == 'Any') return true;

    final t = l.availabilityText.toLowerCase();
    final v = _availability;

    if (v == 'Immediately') {
      return t.contains('immed') || t.contains('now') || t.contains('today');
    }
    if (v == 'Weekends') {
      return t.contains('weekend') || t.contains('sat') || t.contains('sun');
    }
    if (v == 'Weekdays') {
      return t.contains('weekday') ||
          t.contains('mon') ||
          t.contains('tue') ||
          t.contains('wed') ||
          t.contains('thu') ||
          t.contains('fri');
    }

    return t.contains(v.toLowerCase());
  }

  bool _matches(BabysittingListing l) {
    if (l.authorId == widget.myUid) return false;

    if (_pet != 'Any') {
      final wanted = _pet.toLowerCase();
      final types = l.petTypes.map((e) => e.toLowerCase()).toList();
      if (!types.contains(wanted)) return false;
    }

    if (!_availabilityOk(l)) return false;

    if (_query.isEmpty) return true;

    final hay = [
      l.authorName,
      l.title,
      l.description,
      l.city,
      l.governorate,
      l.priceText,
      l.availabilityText,
      l.petTypes.join(' '),
    ].join(' ').toLowerCase();

    return hay.contains(_query);
  }

  double _priceNumber(String text) {
    final m = RegExp(r'(\d+(\.\d+)?)').firstMatch(text.replaceAll(',', '.'));
    if (m == null) return double.nan;
    return double.tryParse(m.group(1) ?? '') ?? double.nan;
  }

  List<BabysittingListing> _sorted(List<BabysittingListing> items) {
    final list = items.toList();

    if (_sort == 'Price ↑') {
      list.sort(
        (a, b) =>
            _priceNumber(a.priceText).compareTo(_priceNumber(b.priceText)),
      );
    } else if (_sort == 'Price ↓') {
      list.sort(
        (a, b) =>
            _priceNumber(b.priceText).compareTo(_priceNumber(a.priceText)),
      );
    } else {
      list.sort((a, b) {
        final ad =
            a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd =
            b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    }
    return list;
  }

  Future<void> _openCreateListing() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateBabysittingListingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BabysittingListing>>(
      stream: BabysittingRepository.instance.streamActiveListings(limit: 200),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
            children: const [
              _BrowseHeroLoading(),
              SizedBox(height: 12),
              _CardSkeleton(),
              SizedBox(height: 12),
              _CardSkeleton(),
            ],
          );
        }

        if (snap.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
            children: [
              _BrowseHero(
                query: _query,
                filtersCount: _activeFiltersCount,
                totalCount: 0,
              ),
              const SizedBox(height: 12),
              _EmptyBrowseState(
                title: 'Could not load listings',
                subtitle: 'Please check your connection and try again.',
                primaryLabel: 'Try again',
                primaryIcon: Icons.refresh_rounded,
                onPrimary: () => setState(() {}),
                secondaryLabel: 'Create listing',
                secondaryIcon: Icons.add_rounded,
                onSecondary: _openCreateListing,
              ),
            ],
          );
        }

        final all = snap.data ?? const [];
        final filtered = all.where(_matches).toList();
        final items = _sorted(filtered);
        final visibleListings = all
            .where((l) => l.authorId != widget.myUid)
            .length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          children: [
            _BrowseHero(
              query: _query,
              filtersCount: _activeFiltersCount,
              totalCount: items.length,
            ),
            const SizedBox(height: 12),
            _BrowseHeader(
              controller: _q,
              onChanged: _onQueryChanged,
              pet: _pet,
              availability: _availability,
              sort: _sort,
              activeFiltersCount: _activeFiltersCount,
              onTapFilters: _openFilters,
              onTapSort: _openSort,
              onResetFilters: _resetFilters,
              onClear: () {
                _q.clear();
                setState(() => _query = '');
              },
            ),
            const SizedBox(height: 12),
            _SectionTitle(
              icon: Icons.pets_rounded,
              title: _query.isEmpty ? 'Available sitters' : 'Search results',
              subtitle: _query.isEmpty
                  ? '$visibleListings active listing${visibleListings == 1 ? '' : 's'} ready to browse.'
                  : '${items.length} listing${items.length == 1 ? '' : 's'} match your search.',
              bg: AppTheme.lilac,
              fg: const Color(0xFF7C62D7),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              _EmptyBrowseState(
                title: visibleListings == 0
                    ? 'No sitters yet'
                    : 'No matches found',
                subtitle: visibleListings == 0
                    ? 'Be the first to publish a babysitting listing in your city.'
                    : 'Try changing filters or broadening your search.',
                primaryLabel: (_query.isNotEmpty || _activeFiltersCount > 0)
                    ? 'Reset search'
                    : 'Create listing',
                primaryIcon: (_query.isNotEmpty || _activeFiltersCount > 0)
                    ? Icons.restart_alt_rounded
                    : Icons.add_rounded,
                onPrimary: () {
                  setState(() {
                    if (_query.isNotEmpty) {
                      _q.clear();
                      _query = '';
                    }
                    _pet = 'Any';
                    _availability = 'Any';
                  });
                },
                secondaryLabel: (_query.isNotEmpty || _activeFiltersCount > 0)
                    ? 'Create listing'
                    : 'Refresh',
                secondaryIcon: (_query.isNotEmpty || _activeFiltersCount > 0)
                    ? Icons.add_rounded
                    : Icons.refresh_rounded,
                onSecondary: () {
                  if (_query.isNotEmpty || _activeFiltersCount > 0) {
                    _openCreateListing();
                  } else {
                    setState(() {});
                  }
                },
              )
            else
              ...List.generate(
                items.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnimatedIn(
                    index: i,
                    child: _ListingCard(listing: items[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CreateListingBanner extends StatelessWidget {
  const _CreateListingBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      shadowOpacity: 0.09,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: const LinearGradient(
                colors: [AppTheme.orchidDark, AppTheme.roseDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppTheme.softShadows(0.08),
            ),
            child: const Icon(
              Icons.add_home_work_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a new listing',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your pricing and availability to start receiving requests.',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(215),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.1,
                    height: 1.14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.mist,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outline),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.orchidDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseHero extends StatelessWidget {
  const _BrowseHero({
    required this.query,
    required this.filtersCount,
    required this.totalCount,
  });

  final String query;
  final int filtersCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final title = query.trim().isEmpty
        ? 'Find a trusted sitter'
        : 'Results for "${query.trim()}"';

    final subtitle = query.trim().isEmpty
        ? 'Compare sitters, pricing, and availability without extra back-and-forth.'
        : '$totalCount listing${totalCount == 1 ? '' : 's'} found${filtersCount > 0 ? ' • $filtersCount filter${filtersCount == 1 ? '' : 's'} active' : ''}.';

    return PremiumPageHeader(
      icon: Icons.pets_rounded,
      iconColor: const Color(0xFF7C62D7),
      title: title,
      subtitle: subtitle,
      badgeLabel: filtersCount > 0 ? '$filtersCount filters' : null,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
    );
  }
}

class _BrowseHeroLoading extends StatelessWidget {
  const _BrowseHeroLoading();

  @override
  Widget build(BuildContext context) {
    return const PremiumSkeletonCard(height: 118, radius: 26);
  }
}

class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader({
    required this.controller,
    required this.onChanged,
    required this.pet,
    required this.availability,
    required this.sort,
    required this.activeFiltersCount,
    required this.onTapFilters,
    required this.onTapSort,
    required this.onResetFilters,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String pet;
  final String availability;
  final String sort;
  final int activeFiltersCount;
  final VoidCallback onTapFilters;
  final VoidCallback onTapSort;
  final VoidCallback onResetFilters;
  final VoidCallback onClear;

  String _filtersSummary() {
    final parts = <String>[];
    if (pet != 'Any') parts.add(pet);
    if (availability != 'Any') parts.add(availability);
    if (parts.isEmpty) return 'All listings';
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchField(
          controller: controller,
          onChanged: onChanged,
          onClear: onClear,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionPill(
                icon: Icons.tune_rounded,
                title: 'Filters',
                subtitle: _filtersSummary(),
                badgeCount: activeFiltersCount,
                onTap: onTapFilters,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionPill(
                icon: Icons.sort_rounded,
                title: 'Sort',
                subtitle: sort,
                onTap: onTapSort,
              ),
            ),
          ],
        ),
        if (activeFiltersCount > 0) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onResetFilters,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text(
                'Reset filters',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.08),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            color: AppTheme.muted.withAlpha(220),
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search sitters, city, pets, or price…',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear'),
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  )
                : const SizedBox(width: 12, height: 38),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
          boxShadow: AppTheme.softShadows(0.08),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.lilac,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF7C62D7)),
            ),
            const SizedBox(width: 12),
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
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(215),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.4,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if ((badgeCount ?? 0) > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.mist,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: AppTheme.orchidDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.6,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.ink.withAlpha(120),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterValues {
  const _FilterValues({required this.pet, required this.availability});

  final String pet;
  final String availability;
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.initialPet,
    required this.initialAvailability,
  });

  final String initialPet;
  final String initialAvailability;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  static const _pets = ['Any', 'Dog', 'Cat', 'Bird', 'Other'];
  static const _availability = ['Any', 'Immediately', 'Weekends', 'Weekdays'];

  late String _pet;
  late String _avail;

  @override
  void initState() {
    super.initState();
    _pet = widget.initialPet;
    _avail = widget.initialAvailability;
  }

  void _reset() {
    setState(() {
      _pet = 'Any';
      _avail = 'Any';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumBottomSheet(
      title: 'Filters',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Pet type', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pets
                .map(
                  (v) => _SelectPill(
                    label: v == 'Any' ? 'All pets' : v,
                    selected: _pet == v,
                    onTap: () => setState(() => _pet = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Availability',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availability
                .map(
                  (v) => _SelectPill(
                    label: v == 'Any' ? 'Any time' : v,
                    selected: _avail == v,
                    onTap: () => setState(() => _avail = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(_FilterValues(pet: _pet, availability: _avail));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orchidDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.value, required this.values});

  final String value;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return _PremiumBottomSheet(
      title: 'Sort by',
      child: Column(
        children: [
          const SizedBox(height: 6),
          ...values.map(
            (v) => ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).pop(v),
              leading: Icon(
                v == value
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: v == value ? AppTheme.orchidDark : AppTheme.muted,
              ),
              title: Text(
                v,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              trailing: v == value ? const Icon(Icons.check_rounded) : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SelectPill extends StatelessWidget {
  const _SelectPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPill(
      label: label,
      selected: selected,
      onTap: onTap,
      showCheckWhenSelected: true,
      fontSize: 11.6,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    );
  }
}

class _PremiumBottomSheet extends StatelessWidget {
  const _PremiumBottomSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.outline),
          boxShadow: AppTheme.softShadows(0.22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final BabysittingListing listing;

  Future<void> _openRequest(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateRequestSheet(listing: listing),
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListingDetailsPage(listing: listing)),
    );
  }

  String _location() {
    return [
      listing.city.trim(),
      listing.governorate.trim(),
    ].where((e) => e.isNotEmpty).join(', ');
  }

  String _availabilityCompact() {
    final text = listing.availabilityText.trim();
    if (text.isEmpty) return 'Available now';
    final lower = text.toLowerCase();
    if (lower.contains('immed') ||
        lower.contains('today') ||
        lower.contains('now')) {
      return 'Available now';
    }
    if (lower.contains('weekend')) return 'Weekends';
    if (lower.contains('weekday')) return 'Weekdays';
    if (lower.contains('flex')) return 'Flexible';
    return text.length <= 24 ? text : '${text.substring(0, 23).trimRight()}…';
  }

  String _petsCompact() {
    final p = listing.petTypes.where((e) => e.trim().isNotEmpty).toList();
    if (p.isEmpty) return 'Any pets';
    if (p.length == 1) return p.first;
    if (p.length == 2) return '${p[0]} & ${p[1]}';
    return '${p.first} +${p.length - 1}';
  }

  String _statusText() {
    if (!listing.isActive) return 'Paused';
    final blocked =
        listing.unavailableDateKeys.length + listing.bookedDateKeys.length;
    if (blocked >= 8) return 'Limited dates';
    return 'Live listing';
  }

  Color _statusBg() {
    if (!listing.isActive) return AppTheme.blush;
    final blocked =
        listing.unavailableDateKeys.length + listing.bookedDateKeys.length;
    if (blocked >= 8) return AppTheme.butter;
    return AppTheme.mint;
  }

  Color _statusFg() {
    if (!listing.isActive) return AppTheme.roseDark;
    final blocked =
        listing.unavailableDateKeys.length + listing.bookedDateKeys.length;
    if (blocked >= 8) return const Color(0xFF8A5A00);
    return const Color(0xFF2F9A6A);
  }

  @override
  Widget build(BuildContext context) {
    final place = _location();

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      shadowOpacity: 0.11,
      onTap: () => _openDetails(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    _statusText(),
                    style: TextStyle(
                      color: _statusFg(),
                      fontWeight: FontWeight.w900,
                      fontSize: 11.6,
                    ),
                  ),
                ),
                const Spacer(),
                _RatingBadge(listingId: listing.id),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              listing.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                height: 1.06,
                letterSpacing: -0.2,
              ),
            ),
            if (place.isNotEmpty) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 17,
                    color: AppTheme.muted.withAlpha(190),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(215),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    uid: listing.authorId,
                    radius: 19,
                    fallbackName: listing.authorName,
                    fallbackPhotoUrl: listing.authorPhotoUrl,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Sitter profile',
                          style: TextStyle(
                            color: AppTheme.muted.withAlpha(210),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (listing.priceText.trim().isNotEmpty)
                    _PricePill(text: listing.priceText),
                ],
              ),
            ),
            if (listing.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                listing.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(176),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.8,
                  height: 1.32,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniMetaPill(
                  icon: Icons.pets_rounded,
                  text: _petsCompact(),
                  bg: AppTheme.surface,
                  fg: AppTheme.ink,
                ),
                _MiniMetaPill(
                  icon: Icons.schedule_rounded,
                  text: _availabilityCompact(),
                  bg: AppTheme.mint,
                  fg: const Color(0xFF2F9A6A),
                ),
                if (listing.bookedDateKeys.isNotEmpty)
                  _MiniMetaPill(
                    icon: Icons.event_busy_rounded,
                    text: '${listing.bookedDateKeys.length} booked',
                    bg: AppTheme.sky,
                    fg: const Color(0xFF4C79C8),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDetails(context),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                    label: const Text('View details'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      foregroundColor: AppTheme.ink,
                      side: const BorderSide(color: AppTheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openRequest(context),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Request stay'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      backgroundColor: AppTheme.orchidDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetaPill extends StatelessWidget {
  const _MiniMetaPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumCardBadge(
      label: text,
      icon: Icons.payments_rounded,
      bg: AppTheme.mist,
      fg: AppTheme.orchidDark,
      borderColor: AppTheme.outline,
      fontSize: 11.8,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    );
  }
}

// ignore: unused_element
class _ListingInfoWrap extends StatelessWidget {
  const _ListingInfoWrap({required this.listing});
  final BabysittingListing listing;

  String _petsCompact(List<String> pets) {
    final p = pets.where((e) => e.trim().isNotEmpty).toList();
    if (p.isEmpty) return 'Any pets';
    if (p.length == 1) return p.first;
    if (p.length == 2) return '${p[0]} & ${p[1]}';
    return '${p.first} +${p.length - 1}';
  }

  String _availabilityCompact(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'Available now';
    final lower = text.toLowerCase();
    if (lower.contains('immed') ||
        lower.contains('today') ||
        lower.contains('now')) {
      return 'Available now';
    }
    if (lower.contains('weekend')) return 'Weekends';
    if (lower.contains('weekday')) return 'Weekdays';
    if (lower.contains('flex')) return 'Flexible';
    if (text.length <= 18) return text;
    return '${text.substring(0, 17).trimRight()}…';
  }

  _AvailLevel _availabilityLevel() {
    final blocked = <String>{
      ...listing.unavailableDateKeys,
      ...listing.bookedDateKeys,
    };
    if (blocked.isEmpty) return _AvailLevel.high;
    final now = DateTime.now();
    var blockedCount = 0;
    for (var i = 0; i < 14; i++) {
      final key = babysittingDateKey(now.add(Duration(days: i)));
      if (blocked.contains(key)) blockedCount++;
    }
    if (blockedCount <= 2) return _AvailLevel.high;
    if (blockedCount <= 7) return _AvailLevel.medium;
    return _AvailLevel.low;
  }

  @override
  Widget build(BuildContext context) {
    final pets = _petsCompact(listing.petTypes);
    final availability = _availabilityCompact(listing.availabilityText);
    final level = _availabilityLevel();

    return Row(
      children: [
        Expanded(
          flex: 9,
          child: _CompactListingMetaCard(
            icon: Icons.pets_rounded,
            label: 'Pets',
            value: pets,
            accent: AppTheme.lilac,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 10,
          child: _CompactListingMetaCard(
            icon: Icons.schedule_rounded,
            label: 'Available',
            value: availability,
            accent: AppTheme.mint,
            badgeText: level.label,
            badgeBg: level.badgeBg,
            badgeFg: level.badgeFg,
          ),
        ),
      ],
    );
  }
}

enum _AvailLevel { high, medium, low }

extension on _AvailLevel {
  String get label {
    switch (this) {
      case _AvailLevel.high:
        return 'High';
      case _AvailLevel.medium:
        return 'Medium';
      case _AvailLevel.low:
        return 'Low';
    }
  }

  Color get badgeBg {
    switch (this) {
      case _AvailLevel.high:
        return AppTheme.mint.withAlpha(220);
      case _AvailLevel.medium:
        return AppTheme.butter.withAlpha(235);
      case _AvailLevel.low:
        return AppTheme.blush.withAlpha(220);
    }
  }

  Color get badgeFg {
    switch (this) {
      case _AvailLevel.high:
        return const Color(0xFF1B5E20);
      case _AvailLevel.medium:
        return const Color(0xFF7A5600);
      case _AvailLevel.low:
        return AppTheme.orchidDark;
    }
  }
}

class _CompactListingMetaCard extends StatelessWidget {
  const _CompactListingMetaCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.badgeText,
    this.badgeBg,
    this.badgeFg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeFg;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withAlpha(138),
              border: Border.all(color: Colors.white.withAlpha(225)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppTheme.ink.withAlpha(220)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(214),
                          fontWeight: FontWeight.w800,
                          fontSize: 11.3,
                          height: 1.02,
                        ),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            color: badgeFg,
                            fontWeight: FontWeight.w900,
                            fontSize: 9.8,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.6,
                    height: 1.16,
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

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BabysitterRatingSummary>(
      stream: BabysittingRepository.instance.streamListingRatingSummary(
        listingId,
      ),
      builder: (context, snap) {
        final summary = snap.data ?? BabysitterRatingSummary.empty;
        final text = summary.hasReviews
            ? '${summary.average.toStringAsFixed(1)} ★'
            : 'New';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withAlpha(summary.hasReviews ? 225 : 208),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _ListingDetailsSheet extends StatelessWidget {
  const _ListingDetailsSheet({required this.listing});
  final BabysittingListing listing;

  @override
  Widget build(BuildContext context) {
    final tags = <Widget>[
      if (listing.priceText.trim().isNotEmpty)
        _InlineTag(icon: Icons.payments_rounded, text: listing.priceText),
      if (listing.petTypes.isNotEmpty)
        _InlineTag(
          icon: Icons.pets_rounded,
          text: listing.petTypes.join(' • '),
        ),
      if (listing.availabilityText.trim().isNotEmpty)
        _InlineTag(
          icon: Icons.schedule_rounded,
          text: listing.availabilityText.trim(),
        ),
    ];

    return _SheetFrame(
      title: listing.title,
      subtitle:
          '${listing.city}${listing.governorate.trim().isEmpty ? '' : ', ${listing.governorate}'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outline),
              gradient: const LinearGradient(
                colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppTheme.softShadows(0.12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      uid: listing.authorId,
                      radius: 20,
                      fallbackName: listing.authorName,
                      fallbackPhotoUrl: listing.authorPhotoUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        listing.authorName,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _RatingBadge(listingId: listing.id),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: tags),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            listing.description,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(175),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _ListingStatsRow(listing: listing),
          const SizedBox(height: 12),
          _AvailabilityPreviewCard(listing: listing),
          const SizedBox(height: 12),
          _ReviewsPreviewCard(listingId: listing.id),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          otherUid: listing.authorId,
                          otherName: listing.authorName,
                          otherPhoto: listing.authorPhotoUrl.trim().isEmpty
                              ? null
                              : listing.authorPhotoUrl,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CreateRequestSheet(listing: listing),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Request'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListingStatsRow extends StatelessWidget {
  const _ListingStatsRow({required this.listing});

  final BabysittingListing listing;

  @override
  Widget build(BuildContext context) {
    final pets = listing.petTypes.isEmpty
        ? 'Any'
        : listing.petTypes.join(' • ');

    final availability = listing.availabilityText.trim().isEmpty
        ? 'Flexible'
        : listing.availabilityText.trim();

    final location = [
      listing.city.trim(),
      listing.governorate.trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    Widget statCard({
      required IconData icon,
      required String label,
      required String value,
      required Color iconBg,
      required Color iconFg,
      Widget? trailing,
    }) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
          boxShadow: AppTheme.softShadows(0.04),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white),
              ),
              child: Icon(icon, color: iconFg, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.6,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: statCard(
                icon: Icons.pets_rounded,
                label: 'Pets',
                value: pets,
                iconBg: AppTheme.lilac,
                iconFg: const Color(0xFF7C62D7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: statCard(
                icon: Icons.schedule_rounded,
                label: 'Availability',
                value: availability,
                iconBg: AppTheme.mint,
                iconFg: const Color(0xFF2F9A6A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        statCard(
          icon: Icons.location_on_rounded,
          label: 'Location',
          value: location.isEmpty ? 'Tunisia' : location,
          iconBg: AppTheme.sky,
          iconFg: const Color(0xFF4C79C8),
          trailing: listing.priceText.trim().isEmpty
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.blush,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    listing.priceText,
                    style: const TextStyle(
                      color: AppTheme.orchidDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.4,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _AvailabilityPreviewCard extends StatelessWidget {
  const _AvailabilityPreviewCard({required this.listing});

  final BabysittingListing listing;

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final blocked = <String>{
      ...listing.unavailableDateKeys,
      ...listing.bookedDateKeys,
    };

    final start = DateTime.now();
    final days = List.generate(
      28,
      (i) => DateTime(start.year, start.month, start.day + i),
    );

    final openCount = days
        .where((d) => !blocked.contains(babysittingDateKey(d)))
        .length;
    final busyCount = days.length - openCount;

    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniSectionHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Availability calendar',
            subtitle: 'Next 28 days',
            iconBg: AppTheme.mint,
            iconFg: Color(0xFF2F9A6A),
          ),
          const SizedBox(height: 10),
          Row(
            children: _weekdayLabels
                .map(
                  (e) => Expanded(
                    child: Text(
                      e,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.ink.withAlpha(155),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: week
                    .map(
                      (d) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _DayCell(
                            date: d,
                            busy: blocked.contains(babysittingDateKey(d)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              _LegendDot(
                color: Color(0xFFCFF6DE),
                label: 'Open',
                labelColor: Color(0xFF2F9A6A),
              ),
              SizedBox(width: 12),
              _LegendDot(
                color: Color(0xFFFFD9D9),
                label: 'Busy',
                labelColor: Color(0xFFE05555),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$openCount open • $busyCount busy in the next 28 days.',
            style: TextStyle(
              color: AppTheme.muted.withAlpha(220),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.busy});

  final DateTime date;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday =
        today.year == date.year &&
        today.month == date.month &&
        today.day == date.day;

    final bg = busy ? const Color(0xFFFFEBEB) : const Color(0xFFE9FFF5);
    final chip = busy ? const Color(0xFFFFD9D9) : const Color(0xFFCFF6DE);
    final fg = busy ? const Color(0xFFE05555) : const Color(0xFF2F9A6A);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isToday ? AppTheme.sky.withAlpha(210) : bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? const Color(0xFF4C79C8) : AppTheme.outline,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 24,
            height: 6,
            decoration: BoxDecoration(
              color: chip,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 6,
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.labelColor,
  });

  final Color color;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.outline),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w900,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _ReviewsPreviewCard extends StatelessWidget {
  const _ReviewsPreviewCard({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BabysittingReview>>(
      stream: BabysittingRepository.instance.streamListingReviewModels(
        listingId,
        limit: 3,
      ),
      builder: (context, snap) {
        final reviews = snap.data ?? const [];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MiniSectionHeader(
                icon: Icons.star_rounded,
                title: 'Reviews',
                subtitle: 'Recent feedback from pet owners',
                iconBg: AppTheme.butter,
                iconFg: Color(0xFFDA8A1F),
              ),
              const SizedBox(height: 12),
              if (reviews.isEmpty)
                Text(
                  'No reviews yet for this listing.',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                ...reviews.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewTile(review: r),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final BabysittingReview review;

  @override
  Widget build(BuildContext context) {
    final created = review.createdAt;
    final dateText = created == null
        ? ''
        : '${created.day}/${created.month}/${created.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                uid: review.requesterId,
                radius: 16,
                fallbackName: review.requesterName,
                fallbackPhotoUrl: review.requesterPhotoUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.requesterName,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (dateText.isNotEmpty)
                Text(
                  dateText,
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(140),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: const Color(0xFFFFB703),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${review.rating}/5',
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(175),
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: AppTheme.orchidDark.withAlpha(180),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    review.comment,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(180),
                      fontWeight: FontWeight.w700,
                      height: 1.24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniSectionHeader extends StatelessWidget {
  const _MiniSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconFg,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconFg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, color: iconFg, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(220),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withAlpha(220),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.muted),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// My listings
// ======================================================

class _MyListingsTab extends StatelessWidget {
  const _MyListingsTab();

  Future<void> _create(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateBabysittingListingSheet(),
    );
  }

  Future<void> _edit(BuildContext context, BabysittingListing listing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateBabysittingListingSheet(editing: listing),
    );
  }

  Future<void> _delete(BuildContext context, BabysittingListing listing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing'),
        content: Text(
          'Delete "${listing.title}" permanently?',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await BabysittingRepository.instance.deleteListing(listing.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete listing: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BabysittingListing>>(
      stream: BabysittingRepository.instance.streamMyListings(limit: 200),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            children: const [
              _CardSkeleton(height: 136),
              SizedBox(height: 12),
              _CardSkeleton(height: 180),
            ],
          );
        }

        final items = snap.data ?? const [];
        final active = items.where((e) => e.isActive).length;
        final paused = items.length - active;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          children: [
            _StatsHero(
              title: 'Your listings',
              subtitle:
                  'Manage pricing, availability, and visibility in one place.',
              badge: '${items.length} total',
              aLabel: 'Active',
              aValue: '$active',
              bLabel: 'Paused',
              bValue: '$paused',
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              _ListingsLaunchCard(onTap: () => _create(context))
            else ...[
              _CreateListingBanner(onTap: () => _create(context)),
              const SizedBox(height: 12),
              ...List.generate(
                items.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnimatedIn(
                    index: i,
                    child: _MyListingCard(
                      listing: items[i],
                      onEdit: () => _edit(context, items[i]),
                      onDelete: () => _delete(context, items[i]),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ListingsLaunchCard extends StatelessWidget {
  const _ListingsLaunchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      shadowOpacity: 0.08,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.mist,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.add_home_work_rounded,
              color: AppTheme.orchidDark,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No listings yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 17.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create one polished offer with price, pets, and availability to start receiving requests.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(210),
              fontWeight: FontWeight.w700,
              fontSize: 12.0,
              height: 1.24,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _LaunchHintChip(icon: Icons.payments_rounded, text: 'Set price'),
              _LaunchHintChip(icon: Icons.pets_rounded, text: 'Pet types'),
              _LaunchHintChip(
                icon: Icons.schedule_rounded,
                text: 'Availability',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create listing'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: AppTheme.orchidDark,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchHintChip extends StatelessWidget {
  const _LaunchHintChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.orchidDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(190),
              fontWeight: FontWeight.w800,
              fontSize: 11.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsHero extends StatelessWidget {
  const _StatsHero({
    required this.title,
    required this.subtitle,
    required this.aLabel,
    required this.aValue,
    required this.bLabel,
    required this.bValue,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String aLabel;
  final String aValue;
  final String bLabel;
  final String bValue;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(26),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      gradient: const LinearGradient(
        colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withAlpha(228),
                  border: Border.all(color: Colors.white),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.home_work_rounded,
                  color: AppTheme.orchidDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.8,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.ink.withAlpha(165),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.7,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null && badge!.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(226),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(185),
                      fontWeight: FontWeight.w900,
                      fontSize: 10.9,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: aLabel,
                  value: aValue,
                  toneBg: AppTheme.mint,
                  toneFg: const Color(0xFF2F9A6A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  label: bLabel,
                  value: bValue,
                  toneBg: const Color(0xFFF5F2F8),
                  toneFg: AppTheme.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.toneBg,
    required this.toneFg,
  });

  final String label;
  final String value;
  final Color toneBg;
  final Color toneFg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(232),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(192),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: toneBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.outline),
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: TextStyle(
                color: toneFg,
                fontWeight: FontWeight.w900,
                fontSize: 12.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  const _MyListingCard({
    required this.listing,
    required this.onEdit,
    required this.onDelete,
  });

  final BabysittingListing listing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = listing.isActive ? 'Active' : 'Paused';
    final statusBg = listing.isActive
        ? const Color(0xFFE9FFF5)
        : const Color(0xFFF5F2F8);
    final statusFg = listing.isActive
        ? const Color(0xFF2F9A6A)
        : const Color(0xFF75708A);

    final location = [
      listing.city.trim(),
      listing.governorate.trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    final pets = listing.petTypes.isEmpty
        ? 'Any pets'
        : listing.petTypes.join(' • ');

    final availability = listing.availabilityText.trim().isEmpty
        ? 'Flexible schedule'
        : listing.availabilityText.trim();

    return PremiumCardSurface(
      radius: BorderRadius.circular(26),
      padding: EdgeInsets.zero,
      shadowOpacity: 0.11,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumSoftPanel(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            radius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            gradient: const LinearGradient(
              colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white.withAlpha(228),
                    border: Border.all(color: Colors.white),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: AppTheme.orchidDark,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.isActive
                            ? 'Visible in browse and ready to receive requests.'
                            : 'Hidden from browse until you activate it again.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.ink.withAlpha(160),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.7,
                          height: 1.16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusFg,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listing.description.trim().isNotEmpty) ...[
                  Text(
                    listing.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(172),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.4,
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (location.isNotEmpty)
                      _MiniChip(icon: Icons.place_rounded, text: location),
                    if (listing.priceText.trim().isNotEmpty)
                      _MiniChip(
                        icon: Icons.payments_rounded,
                        text: listing.priceText,
                      ),
                    _MiniChip(icon: Icons.pets_rounded, text: pets),
                    _MiniChip(icon: Icons.schedule_rounded, text: availability),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await BabysittingRepository.instance
                                .toggleListingActive(
                                  listing.id,
                                  !listing.isActive,
                                );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not update listing: $e'),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          listing.isActive
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(listing.isActive ? 'Pause' : 'Activate'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orchidDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 42),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFFE05555),
                              ),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// Requests
// ======================================================

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BabysittingRequestModel>>(
      stream: BabysittingRepository.instance.streamIncomingRequests(limit: 200),
      builder: (context, inSnap) {
        return StreamBuilder<List<BabysittingRequestModel>>(
          stream: BabysittingRepository.instance.streamOutgoingRequests(
            limit: 200,
          ),
          builder: (context, outSnap) {
            if ((inSnap.connectionState == ConnectionState.waiting &&
                    !inSnap.hasData) ||
                (outSnap.connectionState == ConnectionState.waiting &&
                    !outSnap.hasData)) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                children: const [
                  _CardSkeleton(height: 120),
                  SizedBox(height: 12),
                  _CardSkeleton(height: 170),
                ],
              );
            }

            final incoming = inSnap.data ?? const [];
            final outgoing = outSnap.data ?? const [];
            final visible = _segment == 0 ? incoming : outgoing;

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              children: [
                RequestsHeaderBar(
                  incomingCount: incoming.length,
                  sentCount: outgoing.length,
                  incomingPending: incoming.where((r) => r.isPending).length,
                  sentActive: [
                    ...incoming,
                    ...outgoing,
                  ].where((r) => r.isAccepted).length,
                  completedCount: [
                    ...incoming,
                    ...outgoing,
                  ].where((r) => r.isCompleted).length,
                  segment: _segment,
                  onSegmentChanged: (v) => setState(() => _segment = v),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  _MiniEmpty(
                    title: _segment == 0
                        ? 'No incoming requests'
                        : 'No sent requests',
                    subtitle: _segment == 0
                        ? 'When someone requests your listing, it will appear here.'
                        : 'Requests you send to sitters will appear here.',
                  )
                else
                  ...List.generate(
                    visible.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AnimatedIn(
                        index: i,
                        child: RequestsTimelineCard(
                          req: visible[i],
                          incoming: _segment == 0,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ======================================================
// Shared small widgets
// ======================================================

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.24),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumToneChip(
      label: text,
      icon: icon,
      bg: const Color(0xFFF8F5FF),
      fg: AppTheme.ink.withAlpha(210),
      iconColor: const Color(0xFF7C62D7),
      borderColor: AppTheme.outline,
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      shadowOpacity: 0.08,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.sky,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.pets_outlined,
              color: Color(0xFF4C79C8),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(210),
              fontWeight: FontWeight.w700,
              fontSize: 12.4,
              height: 1.24,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBrowseState extends StatelessWidget {
  const _EmptyBrowseState({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final themed = Theme.of(context).copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.orchidDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppTheme.orchidDark),
      ),
    );

    return Theme(
      data: themed,
      child: PremiumEmptyStateCard(
        icon: Icons.travel_explore_rounded,
        iconColor: const Color(0xFF7C62D7),
        iconBg: AppTheme.lilac,
        title: title,
        subtitle: subtitle,
        primaryLabel: primaryLabel,
        primaryIcon: primaryIcon,
        onPrimary: onPrimary,
        secondaryLabel: secondaryLabel,
        secondaryIcon: secondaryIcon,
        onSecondary: onSecondary,
      ),
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = 220 + ((index > 6 ? 6 : index) * 45);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delay),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) {
        final dy = (1 - t) * 14;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, dy), child: c),
        );
      },
      child: child,
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    return PremiumSkeletonCard(height: height, radius: 24);
  }
}
