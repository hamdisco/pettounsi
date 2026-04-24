import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../ui/app_theme.dart';
import 'pet_reports_repository.dart';

class CreatePetReportSheet extends StatefulWidget {
  const CreatePetReportSheet({super.key, required this.position});

  final LatLng position;

  @override
  State<CreatePetReportSheet> createState() => _CreatePetReportSheetState();
}

class _CreatePetReportSheetState extends State<CreatePetReportSheet> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'lost';
  bool _saving = false;

  final _titleCtrl = TextEditingController();
  final _animalCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _govCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _animalCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _govCtrl.dispose();
    _phoneCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await PetReportsRepository.instance.createReport(
        type: _type,
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        title: _titleCtrl.text.trim(),
        animal: _animalCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        governorate: _govCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        photoUrl: _photoUrlCtrl.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == 'lost'
                ? 'Lost pet report published successfully.'
                : 'Found pet report published successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create report: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final maxSheetHeight = media.size.height * 0.88;
    final lat = widget.position.latitude.toStringAsFixed(4);
    final lng = widget.position.longitude.toStringAsFixed(4);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.outline),
                  boxShadow: AppTheme.softShadows(0.22),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 46,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppTheme.ink.withAlpha(18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.blush,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: const Icon(
                                  Icons.add_location_alt_rounded,
                                  color: AppTheme.orangeDark,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create pet report',
                                      style: TextStyle(
                                        fontSize: 15.6,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.ink,
                                        height: 1.06,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Publish a lost or found report for this location.',
                                      style: TextStyle(
                                        color: AppTheme.muted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.7,
                                        height: 1.12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _saving ? null : () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                                visualDensity: VisualDensity.compact,
                                splashRadius: 18,
                                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.sky,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Text(
                              'Pinned location: $lat, $lng',
                              style: TextStyle(
                                color: AppTheme.ink.withAlpha(185),
                                fontWeight: FontWeight.w800,
                                fontSize: 11.8,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Report type',
                            icon: Icons.pets_rounded,
                            iconBg: AppTheme.lilac,
                            iconFg: const Color(0xFF7C62D7),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _typeChip(
                                  value: 'lost',
                                  label: 'Lost',
                                  icon: Icons.pets,
                                  color: const Color(0xFFE05555),
                                ),
                                _typeChip(
                                  value: 'found',
                                  label: 'Found',
                                  icon: Icons.pets_outlined,
                                  color: const Color(0xFF2F9A6A),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Main details',
                            icon: Icons.edit_note_rounded,
                            iconBg: AppTheme.blush,
                            iconFg: AppTheme.orangeDark,
                            child: Column(
                              children: [
                                _input(
                                  controller: _titleCtrl,
                                  label: 'Title (optional)',
                                  hint: _type == 'lost'
                                      ? 'Lost cat near downtown'
                                      : 'Found dog near the park',
                                  maxLength: 120,
                                ),
                                const SizedBox(height: 10),
                                _input(
                                  controller: _animalCtrl,
                                  label: 'Animal (optional)',
                                  hint: 'Cat, Dog, Bird...',
                                  maxLength: 40,
                                ),
                                const SizedBox(height: 10),
                                _input(
                                  controller: _descCtrl,
                                  label: 'Description',
                                  hint: _type == 'lost'
                                      ? 'Color, collar, last seen details...'
                                      : 'Condition, collar, where you found it...',
                                  maxLines: 4,
                                  minLines: 3,
                                  maxLength: 600,
                                  validator: (v) {
                                    final t = (v ?? '').trim();
                                    if (t.isEmpty) return 'Description is required';
                                    if (t.length < 8) return 'Please add a bit more detail';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Location details',
                            icon: Icons.place_rounded,
                            iconBg: AppTheme.sky,
                            iconFg: const Color(0xFF4C79C8),
                            child: Column(
                              children: [
                                _input(
                                  controller: _addressCtrl,
                                  label: 'Address (optional)',
                                  hint: 'Street, area, landmark...',
                                  maxLength: 140,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _input(
                                        controller: _cityCtrl,
                                        label: 'City (optional)',
                                        hint: 'City',
                                        maxLength: 60,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _input(
                                        controller: _govCtrl,
                                        label: 'Region (optional)',
                                        hint: 'Region',
                                        maxLength: 60,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Contact & photo',
                            icon: Icons.perm_contact_calendar_rounded,
                            iconBg: AppTheme.mint,
                            iconFg: const Color(0xFF2F9A6A),
                            child: Column(
                              children: [
                                _input(
                                  controller: _phoneCtrl,
                                  label: 'Phone (optional)',
                                  hint: '+216 xx xxx xxx',
                                  keyboardType: TextInputType.phone,
                                  maxLength: 40,
                                ),
                                const SizedBox(height: 10),
                                _input(
                                  controller: _photoUrlCtrl,
                                  label: 'Photo URL (optional)',
                                  hint: 'https://...',
                                  keyboardType: TextInputType.url,
                                  maxLength: 2000,
                                  validator: (v) {
                                    final t = (v ?? '').trim();
                                    if (t.isEmpty) return null;
                                    final uri = Uri.tryParse(t);
                                    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
                                      return 'Enter a valid http/https URL';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.lilac,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Text(
                              'Tip: add a clear description and a phone number if you want people to contact you faster.',
                              style: TextStyle(
                                color: AppTheme.ink.withAlpha(185),
                                fontWeight: FontWeight.w700,
                                height: 1.22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _saving ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppTheme.outline),
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7C62D7),
                                        Color(0xFFC86B9A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _saving ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.check_circle_outline_rounded),
                                    label: Text(
                                      _saving ? 'Saving...' : 'Publish report',
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final active = _type == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(18) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : AppTheme.outline,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? color : AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? minLines,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF8F4FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C62D7), width: 1.4),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(icon, color: iconFg, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                    color: AppTheme.ink,
                    height: 1,
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
