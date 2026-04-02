import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import 'babysitting_repository.dart';

class CreateBabysittingListingSheet extends StatefulWidget {
  const CreateBabysittingListingSheet({super.key, this.editing});

  final BabysittingListing? editing;

  @override
  State<CreateBabysittingListingSheet> createState() =>
      _CreateBabysittingListingSheetState();
}

class _CreateBabysittingListingSheetState
    extends State<CreateBabysittingListingSheet> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _city = TextEditingController();
  final _gov = TextEditingController();
  final _price = TextEditingController();
  final _availability = TextEditingController();

  final Set<String> _petTypes = {};
  final List<String> _unavailable = [];

  bool _loading = false;

  bool get _editing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _title.text = e.title;
      _desc.text = e.description;
      _city.text = e.city;
      _gov.text = e.governorate;
      _price.text = e.priceText;
      _availability.text = e.availabilityText;
      _petTypes.addAll(e.petTypes);
      _unavailable.addAll(e.unavailableDateKeys);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _city.dispose();
    _gov.dispose();
    _price.dispose();
    _availability.dispose();
    super.dispose();
  }

  Future<void> _pickUnavailableDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (d == null) return;

    final key = babysittingDateKey(d);
    if (_unavailable.contains(key)) return;
    setState(() => _unavailable.add(key));
  }

  void _togglePet(String v) {
    setState(() {
      if (_petTypes.contains(v)) {
        _petTypes.remove(v);
      } else {
        _petTypes.add(v);
      }
    });
  }

  String _heroSubtitle() {
    if (_editing) {
      return 'Update your offer, and keep your listing competitive.';
    }
    return 'Build a trustworthy sitter profile.';
  }

  String _dateSummary() {
    if (_unavailable.isEmpty) return 'No blocked dates';
    if (_unavailable.length == 1) return '1 blocked date';
    return '${_unavailable.length} blocked dates';
  }

  String _selectedPetsSummary() {
    if (_petTypes.isEmpty) return 'No pet type selected yet.';
    final items = _petTypes.toList()..sort();
    return 'Selected: ${items.join(' • ')}';
  }

  void _applyAvailabilityPreset(String value) {
    setState(() => _availability.text = value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _title.text.trim();
    final desc = _desc.text.trim();
    final city = _city.text.trim();
    final gov = _gov.text.trim();
    final price = _price.text.trim();
    final avail = _availability.text.trim();

    setState(() => _loading = true);
    try {
      if (!_editing) {
        await BabysittingRepository.instance.createListing(
          title: title,
          description: desc,
          city: city,
          governorate: gov,
          priceText: price,
          petTypes: _petTypes.toList(),
          availabilityText: avail,
          unavailableDateKeys: _unavailable,
        );
      } else {
        final e = widget.editing!;
        await BabysittingRepository.instance.updateListing(
          listingId: e.id,
          title: title,
          description: desc,
          city: city,
          governorate: gov,
          priceText: price,
          petTypes: _petTypes.toList(),
          availabilityText: avail,
          isActive: e.isActive,
          unavailableDateKeys: _unavailable,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? 'Listing updated' : 'Listing published'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save listing: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.outline),
                boxShadow: AppTheme.softShadows(0.24),
              ),
              child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _editing ? 'Edit listing' : 'Create listing',
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _HeroCard(
                  title: _editing
                      ? 'Refine your babysitting offer'
                      : 'Publish a sitter profile',
                  subtitle: _heroSubtitle(),
                  trailingText: _dateSummary(),
                ),
                const SizedBox(height: 12),

                _Section(
                  title: 'Basics',
                  icon: Icons.notes_rounded,
                  iconBg: AppTheme.lilac,
                  iconFg: const Color(0xFF7C62D7),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _title,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Listing title',
                          hintText: 'Example: Loving weekend sitter in Sousse',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return 'Required';
                          if (t.length > 120) return 'Max 120 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _desc,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText:
                              'Describe your experience, the pets you care for, and how a stay usually works.',
                          prefixIcon: Icon(Icons.notes_rounded),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return 'Required';
                          if (t.length > 2000) return 'Max 2000 characters';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _Section(
                  title: 'Location',
                  icon: Icons.place_rounded,
                  iconBg: AppTheme.sky,
                  iconFg: const Color(0xFF4C79C8),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _city,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_city_rounded),
                        ),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _gov,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Governorate',
                          prefixIcon: Icon(Icons.map_rounded),
                        ),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _Section(
                  title: 'Pets & availability',
                  icon: Icons.pets_rounded,
                  iconBg: AppTheme.mint,
                  iconFg: const Color(0xFF2F9A6A),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pet types you accept',
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.35,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: const [
                          'Dog',
                          'Cat',
                          'Bird',
                          'Other',
                        ].map((v) => _PetChip(label: v)).toList(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedPetsSummary(),
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(215),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.6,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _availability,
                        decoration: const InputDecoration(
                          labelText: 'Availability',
                          hintText: 'Example: weekends, evenings, flexible',
                          prefixIcon: Icon(Icons.schedule_rounded),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return 'Required';
                          if (t.length > 300) return 'Max 300 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Available now',
                          'Weekends',
                          'Evenings',
                          'Flexible',
                        ]
                            .map(
                              (v) => _QuickAvailabilityChip(
                                label: v,
                                selected: _availability.text.trim() == v,
                                onTap: _loading ? null : () => _applyAvailabilityPreset(v),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _Section(
                  title: 'Pricing',
                  icon: Icons.payments_rounded,
                  iconBg: AppTheme.mist,
                  iconFg: AppTheme.orchidDark,
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(
                      labelText: 'Price (optional)',
                      hintText: 'Example: 25 TND/day',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.length > 80) return 'Max 80 characters';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 12),

                _Section(
                  title: 'Unavailable dates',
                  icon: Icons.event_busy_rounded,
                  iconBg: const Color(0xFFFFF2DB),
                  iconFg: const Color(0xFFDA8A1F),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _pickUnavailableDate,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add blocked date'),
                      ),
                      const SizedBox(height: 10),
                      if (_unavailable.isEmpty)
                        Text(
                          'No unavailable dates added yet.',
                          style: TextStyle(
                            color: AppTheme.muted.withAlpha(220),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (() {
                            final ks = _unavailable.toList()..sort();
                            return ks
                                .map(
                                  (k) => InputChip(
                                    label: Text(
                                      k,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    onDeleted: _loading
                                        ? null
                                        : () => setState(
                                            () => _unavailable.remove(k),
                                          ),
                                  ),
                                )
                                .toList();
                          })(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orchidDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : Icon(
                            _editing
                                ? Icons.save_rounded
                                : Icons.publish_rounded,
                            size: 18,
                          ),
                    label: Text(_editing ? 'Save changes' : 'Publish listing'),
                  ),
                ),
              ],
            ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool isPetSelected(String v) => _petTypes.contains(v);
  void togglePet(String v) => _togglePet(v);
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.trailingText,
  });

  final String title;
  final String subtitle;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppTheme.orchidDark,
              size: 28,
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
                    fontSize: 15.5,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(225),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              trailingText,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(icon, size: 18, color: iconFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PetChip extends StatelessWidget {
  const _PetChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final st = context
        .findAncestorStateOfType<_CreateBabysittingListingSheetState>();
    final selected = st?.isPetSelected(label) ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: st?._loading == true ? null : () => st?.togglePet(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected ? AppTheme.orchidDark : Colors.white,
            border: Border.all(
              color: selected ? AppTheme.orchidDark : AppTheme.outline,
            ),
            boxShadow: selected ? AppTheme.softShadows(0.06) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white.withAlpha(34) : AppTheme.mist,
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? Icons.check_rounded : Icons.pets_rounded,
                  size: 16,
                  color: selected ? Colors.white : AppTheme.orchidDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.6,
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

class _QuickAvailabilityChip extends StatelessWidget {
  const _QuickAvailabilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.mist : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppTheme.orchidDark : AppTheme.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.orchidDark : AppTheme.ink,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}
