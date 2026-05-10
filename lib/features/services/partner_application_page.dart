import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/user_identity_service.dart';
import '../../ui/app_theme.dart';

class PartnerApplicationPage extends StatefulWidget {
  const PartnerApplicationPage({super.key, this.initialType, this.initialPlan});

  final String? initialType;
  final String? initialPlan;

  @override
  State<PartnerApplicationPage> createState() => _PartnerApplicationPageState();
}

class _PartnerApplicationPageState extends State<PartnerApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _city = TextEditingController();
  final _contactName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();

  static const _types = <String, String>{
    'vet': 'Vet clinic',
    'pet_shop': 'Pet shop',
    'grooming': 'Grooming',
    'trainer': 'Trainer',
    'shelter': 'Shelter / rescue',
    'pet_friendly_place': 'Pet-friendly place',
    'other': 'Other service',
  };

  static const _plans = <String, _BusinessPlan>{
    'free_listing': _BusinessPlan(
      title: 'Free Listing',
      price: '0 TND / month',
      summary:
          'Basic business request with city/category visibility after review.',
      benefits: [
        'Business profile request',
        'Category and city listing',
        'Basic contact details',
      ],
    ),
    'featured_map': _BusinessPlan(
      title: 'Featured Partner',
      price: '49 TND / month',
      summary: 'For vets and shops that want stronger local discovery.',
      benefits: [
        'Featured placement',
        'Partner badge',
        'Logo/photos',
        'Call and directions focus',
      ],
    ),
    'shop_growth': _BusinessPlan(
      title: 'Growth Partner',
      price: '69 TND / month',
      summary:
          'For shops, groomers, and clinics that want offers and recurring visibility.',
      benefits: [
        'Featured placement',
        'Partner offer card',
        'Category boost',
        'Monthly performance notes',
      ],
    ),
    'pilot': _BusinessPlan(
      title: 'Premium Local Partner',
      price: '99 TND / month',
      summary: 'For high-priority local partners and launch campaigns.',
      benefits: [
        'Top placement',
        'Multiple monthly offers',
        'Campaign visibility',
        'Priority review',
      ],
    ),
    'partner_offers': _BusinessPlan(
      title: 'Partner Offers',
      price: 'From 49 TND / month',
      summary: 'Promote food, grooming, checkups, and accessory offers.',
      benefits: ['Offer card', 'Limited campaign slot', 'Partner visibility'],
    ),
    'vet_care_plan': _BusinessPlan(
      title: 'Vet Care Plan',
      price: 'From 69 TND / month',
      summary: 'Clinic packages prepared for PetTounsi pet owners.',
      benefits: [
        'Care package listing',
        'Clinic partner badge',
        'Discovery placement',
      ],
    ),
  };

  late String _type;
  late String _plan;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _type = _types.containsKey(widget.initialType)
        ? widget.initialType!
        : 'vet';
    _plan = _plans.containsKey(widget.initialPlan)
        ? widget.initialPlan!
        : 'free_listing';
    final user = FirebaseAuth.instance.currentUser;
    _contactName.text = user?.displayName ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _businessName.dispose();
    _city.dispose();
    _contactName.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

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
      await FirebaseFirestore.instance.collection('partner_applications').add({
        'kind': 'business_partner',
        'applicantUid': user.uid,
        'applicantEmail': user.email,
        'applicantName': (await UserIdentityService.instance.getForUid(
          user.uid,
          authUser: user,
        )).safeName,
        'businessType': _type,
        'businessName': _businessName.text.trim(),
        'city': _city.text.trim(),
        'contactName': _contactName.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'planInterest': _plan,
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
          title: const Text('Request sent'),
          content: const Text('Your partner request is pending review.'),
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
          content: Text('Could not send the request. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlan = _plans[_plan]!;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Business partner')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const _PageHeader(),
              const SizedBox(height: 14),
              _PlanSummary(plan: selectedPlan),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Business',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Business type',
                    ),
                    items: _types.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessName,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Business name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _city,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _plan,
                    decoration: const InputDecoration(
                      labelText: 'Plan interest',
                    ),
                    items: _plans.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text('${e.value.title} · ${e.value.price}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _plan = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Contact',
                children: [
                  TextFormField(
                    controller: _contactName,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Contact name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Notes',
                children: [
                  TextFormField(
                    controller: _notes,
                    maxLines: 4,
                    maxLength: 600,
                    decoration: const InputDecoration(
                      labelText: 'Business goals, services, or offer ideas',
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
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_submitting ? 'Sending…' : 'Send partner request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply as a partner',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
              height: 1.05,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'For vets, pet shops, groomers, trainers, shelters, and pet-friendly places.',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final _BusinessPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.orange.withAlpha(110)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                    height: 1.1,
                  ),
                ),
              ),
              Text(
                plan.price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.orangeDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.summary,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.benefits.map((item) => _SmallLine(text: item)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

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

class _SmallLine extends StatelessWidget {
  const _SmallLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppTheme.orangeDark,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                color: AppTheme.muted,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessPlan {
  const _BusinessPlan({
    required this.title,
    required this.price,
    required this.summary,
    required this.benefits,
  });

  final String title;
  final String price;
  final String summary;
  final List<String> benefits;
}
