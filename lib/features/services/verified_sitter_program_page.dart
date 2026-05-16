import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/user_identity_service.dart';
import '../../ui/app_theme.dart';
import '../pet_babysitting/pet_babysitting_page.dart';

class VerifiedSitterProgramPage extends StatefulWidget {
  const VerifiedSitterProgramPage({super.key, this.initialPlan});

  final String? initialPlan;

  @override
  State<VerifiedSitterProgramPage> createState() =>
      _VerifiedSitterProgramPageState();
}

class _VerifiedSitterProgramPageState extends State<VerifiedSitterProgramPage> {
  final _formKey = GlobalKey<FormState>();
  final _city = TextEditingController();
  final _experience = TextEditingController();
  final _capacity = TextEditingController();
  final _priceRange = TextEditingController();
  final _notes = TextEditingController();

  final Set<String> _petTypes = {'dogs'};
  String _plan = 'verified';
  bool _identityReady = false;
  bool _submitting = false;

  static const _plans = <String, _SitterPlan>{
    'starter': _SitterPlan(
      title: 'Free listing',
      price: '0 TND / month',
      summary: 'Create a normal sitter listing and collect real reviews first.',
    ),
    'verified': _SitterPlan(
      title: 'Verified sitter',
      price: '9 TND / month',
      summary:
          'For sitters ready for profile review and stronger trust signals.',
    ),
    'pro_visibility': _SitterPlan(
      title: 'Pro visibility',
      price: '19 TND / month',
      summary:
          'For active sitters who want better visibility after quality review.',
    ),
  };

  @override
  void initState() {
    super.initState();
    _plan = _plans.containsKey(widget.initialPlan)
        ? widget.initialPlan!
        : 'verified';
  }

  @override
  void dispose() {
    _city.dispose();
    _experience.dispose();
    _capacity.dispose();
    _priceRange.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Required';
    return null;
  }

  void _togglePet(String pet) {
    setState(() {
      if (_petTypes.contains(pet)) {
        _petTypes.remove(pet);
      } else {
        _petTypes.add(pet);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_petTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one pet type.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final now = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('verified_sitter_applications')
          .add({
            'kind': 'verified_sitter',
            'applicantUid': user.uid,
            'applicantEmail': user.email,
            'applicantName': (await UserIdentityService.instance.getForUid(
              user.uid,
              authUser: user,
            )).safeName,
            'city': _city.text.trim(),
            'petTypes': _petTypes.toList()..sort(),
            'experience': _experience.text.trim(),
            'weeklyCapacity': _capacity.text.trim(),
            'priceRange': _priceRange.text.trim(),
            'planInterest': _plan,
            'planTitle': _plans[_plan]?.title,
            'planFee': _plans[_plan]?.price,
            'identityReady': _identityReady,
            'notes': _notes.text.trim(),
            'status': 'pending',
            'source': 'services_partner_hub',
            'createdAt': now,
            'updatedAt': now,
          });

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application sent'),
          content: const Text(
            'Your verified sitter request is now pending review.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send the application. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openListings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PetBabysittingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlan = _plans[_plan]!;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Verified sitter')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _SitterIntro(onListings: _openListings),
              const SizedBox(height: 14),
              _SitterPlanSummary(plan: selectedPlan),
              const SizedBox(height: 14),
              const _TierCard(),
              const SizedBox(height: 14),
              _CardBlock(
                title: 'Application',
                children: [
                  TextFormField(
                    controller: _city,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pet types',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PetChip(
                        label: 'Dogs',
                        value: 'dogs',
                        selected: _petTypes.contains('dogs'),
                        onTap: _togglePet,
                      ),
                      _PetChip(
                        label: 'Cats',
                        value: 'cats',
                        selected: _petTypes.contains('cats'),
                        onTap: _togglePet,
                      ),
                      _PetChip(
                        label: 'Birds',
                        value: 'birds',
                        selected: _petTypes.contains('birds'),
                        onTap: _togglePet,
                      ),
                      _PetChip(
                        label: 'Other',
                        value: 'other',
                        selected: _petTypes.contains('other'),
                        onTap: _togglePet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _experience,
                    maxLines: 3,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Experience',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _capacity,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Weekly capacity',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceRange,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                    decoration: const InputDecoration(labelText: 'Price range'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _plan,
                    decoration: const InputDecoration(
                      labelText: 'Program interest',
                    ),
                    items: _plans.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              '${e.value.title} · ${e.value.price}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _plan = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: _identityReady,
                    onChanged: (value) =>
                        setState(() => _identityReady = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Ready for verification checks',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                      ),
                    ),
                    subtitle: const Text(
                      'Photo, profile details, and basic trust review.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_rounded, size: 18),
                label: Text(
                  _submitting ? 'Sending…' : 'Apply for verification',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SitterIntro extends StatelessWidget {
  const _SitterIntro({required this.onListings});

  final VoidCallback onListings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.softOrange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.orangeDark,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Sitter Program',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Clear monthly options for sitters who want profile review and stronger visibility.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SitterPlan {
  const _SitterPlan({
    required this.title,
    required this.price,
    required this.summary,
  });

  final String title;
  final String price;
  final String summary;
}

class _SitterPlanSummary extends StatelessWidget {
  const _SitterPlanSummary({required this.plan});

  final _SitterPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.softOrange,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppTheme.orangeDark,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink,
                          height: 1.05,
                        ),
                      ),
                    ),
                    Text(
                      plan.price,
                      style: const TextStyle(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.orangeDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  plan.summary,
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted,
                    height: 1.28,
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

class _TierCard extends StatelessWidget {
  const _TierCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program rules',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          _WhiteBullet(text: 'Free listing remains available'),
          _WhiteBullet(text: 'Paid plans start only after review/approval'),
          _WhiteBullet(
            text:
                'Pro visibility depends on activity, reviews, and care quality',
          ),
        ],
      ),
    );
  }
}

class _WhiteBullet extends StatelessWidget {
  const _WhiteBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PetChip extends StatelessWidget {
  const _PetChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(value),
      selectedColor: AppTheme.softOrange,
      checkmarkColor: AppTheme.orangeDark,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w900,
        color: selected ? AppTheme.orangeDark : AppTheme.ink,
      ),
      side: const BorderSide(color: AppTheme.outline),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
