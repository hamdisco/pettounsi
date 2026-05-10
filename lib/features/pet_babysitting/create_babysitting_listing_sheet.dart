import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/user_avatar.dart';
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

    for (final c in [_title, _desc, _city, _gov, _price, _availability]) {
      c.addListener(_refreshPreview);
    }
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
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
    return _editing
        ? 'Update the details owners check before requesting.'
        : 'Create a clear offer with price, pets, location, and availability.';
  }

  String _dateSummary() {
    if (_unavailable.isEmpty) return 'No blocked dates';
    if (_unavailable.length == 1) return '1 blocked date';
    return '${_unavailable.length} blocked dates';
  }

  String _selectedPetsSummary() {
    if (_petTypes.isEmpty) return 'Choose at least one pet type.';
    final items = _petTypes.toList()..sort();
    return items.join(' • ');
  }

  void _applyAvailabilityPreset(String value) {
    setState(() => _availability.text = value);
  }

  void _applyPricePreset(String value) {
    setState(() => _price.text = value);
  }

  void _applyDescriptionTemplate(String value) {
    final current = _desc.text.trim();
    setState(() {
      _desc.text = current.isEmpty ? value : '$current\n\n$value';
      _desc.selection = TextSelection.collapsed(offset: _desc.text.length);
    });
  }

  int _qualityScore() {
    var score = 0;
    if (_title.text.trim().length >= 8) score++;
    if (_desc.text.trim().length >= 80) score++;
    if (_city.text.trim().isNotEmpty && _gov.text.trim().isNotEmpty) score++;
    if (_price.text.trim().isNotEmpty) score++;
    if (_petTypes.isNotEmpty) score++;
    if (_availability.text.trim().isNotEmpty) score++;
    return score;
  }

  String _qualityLabel() {
    final score = _qualityScore();
    if (score >= 6) return 'Ready to publish';
    if (score >= 4) return 'Almost ready';
    return 'Missing essentials';
  }

  String _qualityHint() {
    final missing = <String>[];
    if (_title.text.trim().length < 8) missing.add('clear title');
    if (_desc.text.trim().length < 80) missing.add('service details');
    if (_city.text.trim().isEmpty || _gov.text.trim().isEmpty) {
      missing.add('location');
    }
    if (_price.text.trim().isEmpty) missing.add('price');
    if (_petTypes.isEmpty) missing.add('pet types');
    if (_availability.text.trim().isEmpty) missing.add('availability');

    if (missing.isEmpty) {
      return 'Owners can understand your offer without asking basic questions.';
    }
    return 'Add: ${missing.take(3).join(', ')}${missing.length > 3 ? '…' : ''}.';
  }

  Color _qualityColor() {
    final score = _qualityScore();
    if (score >= 6) return const Color(0xFF2F9A6A);
    if (score >= 4) return const Color(0xFFB87516);
    return AppTheme.roseDark;
  }

  String _previewTitle() {
    final title = _title.text.trim();
    return title.isEmpty ? 'Your sitter profile' : title;
  }

  String _previewLocation() {
    final parts = [_city.text.trim(), _gov.text.trim()]
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Add your location';
    return parts.join(', ');
  }

  String _previewPrice() {
    final value = _price.text.trim();
    return value.isEmpty ? 'Ask in chat' : value;
  }

  String _previewAvailability() {
    final value = _availability.text.trim();
    return value.isEmpty ? 'Add availability' : value;
  }

  String _formatDateChip(String key) {
    final d = babysittingDateFromKey(key);
    if (d == null) return key;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_petTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one pet type.')),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save listing: $e')),
      );
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _editing ? 'Edit sitter profile' : 'Create sitter profile',
                                style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _heroSubtitle(),
                                style: TextStyle(
                                  color: AppTheme.muted.withAlpha(215),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                      title: _previewTitle(),
                      subtitle: 'Public listing preview',
                      trailingText: _dateSummary(),
                      location: _previewLocation(),
                      price: _previewPrice(),
                      availability: _previewAvailability(),
                      petSummary: _selectedPetsSummary(),
                      authorName: widget.editing?.authorName ?? 'You',
                      authorPhotoUrl: widget.editing?.authorPhotoUrl ?? '',
                    ),
                    const SizedBox(height: 10),
                    _QualityCard(
                      score: _qualityScore(),
                      label: _qualityLabel(),
                      hint: _qualityHint(),
                      color: _qualityColor(),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Profile',
                      icon: Icons.pets_rounded,
                      iconBg: AppTheme.lilac,
                      iconFg: const Color(0xFF7C62D7),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _title,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Weekend sitter in Sousse',
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
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'About your service',
                              hintText:
                                  'Describe your routine, experience, and what pet owners can expect.',
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
                          const SizedBox(height: 10),
                          _CareDetailsExpander(
                            onSelected: _loading ? null : _applyDescriptionTemplate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Location & pricing',
                      icon: Icons.place_rounded,
                      iconBg: AppTheme.sky,
                      iconFg: const Color(0xFF4C79C8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _city,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                    prefixIcon: Icon(Icons.location_city_rounded),
                                  ),
                                  validator: (v) =>
                                      (v ?? '').trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _gov,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Governorate',
                                    prefixIcon: Icon(Icons.map_rounded),
                                  ),
                                  validator: (v) =>
                                      (v ?? '').trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _price,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              hintText: '25 TND/day',
                              prefixIcon: Icon(Icons.payments_rounded),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.length > 80) return 'Max 80 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _PresetChips(
                            title: 'Common pricing',
                            values: const [
                              '15 TND/day',
                              '20 TND/day',
                              '25 TND/day',
                              'Ask in chat',
                            ],
                            selected: _price.text.trim(),
                            onSelected: _loading ? null : _applyPricePreset,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Pets & availability',
                      icon: Icons.schedule_rounded,
                      iconBg: AppTheme.mint,
                      iconFg: const Color(0xFF2F9A6A),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pet types',
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
                              hintText: 'Weekends, evenings, flexible',
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
                                    onTap: _loading
                                        ? null
                                        : () => _applyAvailabilityPreset(v),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          const _GuidanceNote(
                            icon: Icons.event_available_rounded,
                            title: 'Availability',
                            text:
                                'Keep this simple. Owners mainly need to know when they can request you.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Blocked dates',
                      icon: Icons.event_busy_rounded,
                      iconBg: const Color(0xFFFFF2DB),
                      iconFg: const Color(0xFFDA8A1F),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _pickUnavailableDate,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add date'),
                          ),
                          const SizedBox(height: 10),
                          if (_unavailable.isEmpty)
                            Text(
                              'No blocked dates yet.',
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
                                          _formatDateChip(k),
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
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _editing
                                  ? 'Save after checking price, dates, and care details.'
                                  : 'Publish only when the offer is clear and ready for requests.',
                              style: TextStyle(
                                color: AppTheme.muted.withAlpha(220),
                                fontWeight: FontWeight.w700,
                                height: 1.24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orangeDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                            ),
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _editing
                                        ? Icons.save_rounded
                                        : Icons.publish_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _editing ? 'Save changes' : 'Publish listing',
                            ),
                          ),
                        ],
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


class _QualityCard extends StatelessWidget {
  const _QualityCard({
    required this.score,
    required this.label,
    required this.hint,
    required this.color,
  });

  final int score;
  final String label;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 6).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.workspace_premium_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: progress,
                    backgroundColor: AppTheme.outline.withAlpha(120),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  hint,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.7,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$score/6',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}


class _CareDetailsExpander extends StatelessWidget {
  const _CareDetailsExpander({required this.onSelected});

  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.softOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.orangeDark,
              size: 17,
            ),
          ),
          title: const Text(
            'Quick care details',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12.8,
            ),
          ),
          subtitle: Text(
            'Optional phrases to make the description clearer.',
            style: TextStyle(
              color: AppTheme.muted.withAlpha(210),
              fontWeight: FontWeight.w700,
              fontSize: 11.2,
            ),
          ),
          children: [
            _TemplateChips(
              title: 'Add to description',
              items: const {
                'Updates':
                    'I can send photos and short updates during the stay.',
                'Routine':
                    'I will follow the owner’s feeding and care routine.',
                'Medication':
                    'Please share medication timing and health notes before the stay.',
                'Walks':
                    'I can provide walks, playtime, and quiet rest based on the pet’s habits.',
              },
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateChips extends StatelessWidget {
  const _TemplateChips({
    required this.title,
    required this.items,
    required this.onSelected,
  });

  final String title;
  final Map<String, String> items;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.muted.withAlpha(220),
            fontWeight: FontWeight.w900,
            fontSize: 11.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.entries
              .map(
                (entry) => ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed:
                      onSelected == null ? null : () => onSelected!(entry.value),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.muted.withAlpha(220),
            fontWeight: FontWeight.w900,
            fontSize: 11.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = selected == value;
            return ChoiceChip(
              label: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              selected: isSelected,
              onSelected: onSelected == null ? null : (_) => onSelected!(value),
              selectedColor: AppTheme.orangeDark.withAlpha(28),
              side: BorderSide(
                color: isSelected ? AppTheme.orangeDark : AppTheme.outline,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GuidanceNote extends StatelessWidget {
  const _GuidanceNote({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.orangeDark, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(225),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.2,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.location,
    required this.price,
    required this.availability,
    required this.petSummary,
    required this.authorName,
    required this.authorPhotoUrl,
  });

  final String title;
  final String subtitle;
  final String trailingText;
  final String location;
  final String price;
  final String availability;
  final String petSummary;
  final String authorName;
  final String authorPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                uid: '',
                radius: 24,
                fallbackName: authorName,
                fallbackPhotoUrl: authorPhotoUrl,
              ),
              const SizedBox(width: 11),
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
                        fontSize: 15.4,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(220),
                        fontWeight: FontWeight.w700,
                        fontSize: 11.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  trailingText,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Icon(Icons.place_rounded, size: 16, color: AppTheme.muted.withAlpha(230)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(230),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewPill(
                icon: Icons.payments_rounded,
                label: price,
                bg: AppTheme.mist,
                fg: AppTheme.orchidDark,
              ),
              _PreviewPill(
                icon: Icons.pets_rounded,
                label: petSummary,
                bg: AppTheme.sky,
                fg: const Color(0xFF4C79C8),
              ),
              _PreviewPill(
                icon: Icons.schedule_rounded,
                label: availability,
                bg: AppTheme.mint,
                fg: const Color(0xFF2F9A6A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
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
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.6,
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
