import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import 'partner_application_page.dart';
import 'verified_sitter_program_page.dart';

class ServicesHubPage extends StatelessWidget {
  const ServicesHubPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _HubHeader(
          onBusiness: () => _push(context, const PartnerApplicationPage()),
          onSitter: () => _push(context, const VerifiedSitterProgramPage()),
        ),
        const SizedBox(height: 18),
        _ProgramSplit(
          onBusiness: () => _push(context, const PartnerApplicationPage()),
          onSitter: () => _push(context, const VerifiedSitterProgramPage()),
        ),
        const SizedBox(height: 22),
        _SectionTitle(
          title: 'Verified sitter plans',
          subtitle: 'For sitters who want more trust and visibility.',
        ),
        const SizedBox(height: 10),
        _PlanCard(
          title: 'Free listing',
          price: '0 TND',
          period: '/ month',
          badge: 'Start',
          benefits: const [
            'Basic sitter profile',
            'Receive requests',
            'Reviews after completed stays',
          ],
          onTap: () => _push(
            context,
            const VerifiedSitterProgramPage(initialPlan: 'starter'),
          ),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          title: 'Verified Sitter',
          price: '9 TND',
          period: '/ month',
          badge: 'Trust',
          highlighted: true,
          benefits: const [
            'Verified profile badge',
            'Higher sitter placement',
            'Trust checklist review',
            'Review highlights',
          ],
          onTap: () => _push(
            context,
            const VerifiedSitterProgramPage(initialPlan: 'verified'),
          ),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          title: 'Active Sitter Pro',
          price: '19 TND',
          period: '/ month',
          badge: 'Growth',
          benefits: const [
            'Priority city visibility',
            'Availability promotion',
            'Monthly activity summary',
            'Best for regular requests',
          ],
          onTap: () => _push(
            context,
            const VerifiedSitterProgramPage(initialPlan: 'pro_visibility'),
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle(
          title: 'Business partner plans',
          subtitle:
              'For vets, pet shops, groomers, trainers, and pet-friendly places.',
        ),
        const SizedBox(height: 10),
        _PlanCard(
          title: 'Free Listing',
          price: '0 TND',
          period: '/ month',
          badge: 'Directory',
          benefits: const [
            'Business profile request',
            'Category and city listing',
            'Basic contact details',
          ],
          onTap: () => _push(
            context,
            const PartnerApplicationPage(initialPlan: 'free_listing'),
          ),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          title: 'Featured Partner',
          price: '49 TND',
          period: '/ month',
          badge: 'Visibility',
          highlighted: true,
          benefits: const [
            'Featured placement in discovery',
            'Partner badge',
            'Logo and photos',
            'Call and directions focus',
          ],
          onTap: () => _push(
            context,
            const PartnerApplicationPage(initialPlan: 'featured_map'),
          ),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          title: 'Growth Partner',
          price: '69 TND',
          period: '/ month',
          badge: 'Offers',
          benefits: const [
            'Featured placement',
            'Partner offer card',
            'Category visibility boost',
            'Monthly performance notes',
          ],
          onTap: () => _push(
            context,
            const PartnerApplicationPage(initialPlan: 'shop_growth'),
          ),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          title: 'Premium Local Partner',
          price: '99 TND',
          period: '/ month',
          badge: 'Premium',
          benefits: const [
            'Top local placement',
            'Multiple monthly offers',
            'Campaign visibility',
            'Priority partner review',
          ],
          onTap: () => _push(
            context,
            const PartnerApplicationPage(initialPlan: 'pilot'),
          ),
        ),
        const SizedBox(height: 20),
        const _CommercialOptions(),
        const SizedBox(height: 20),
        _ApplyPanel(
          onBusiness: () => _push(context, const PartnerApplicationPage()),
          onSitter: () => _push(context, const VerifiedSitterProgramPage()),
        ),
        const SizedBox(height: 10),
        const _PricingNote(),
      ],
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({required this.onBusiness, required this.onSitter});

  final VoidCallback onBusiness;
  final VoidCallback onSitter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partner Hub',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
              height: 1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Programs for verified sitters and local pet businesses.',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onBusiness,
                  child: const Text('Business partner'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSitter,
                  child: const Text('Verified sitter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgramSplit extends StatelessWidget {
  const _ProgramSplit({required this.onBusiness, required this.onSitter});

  final VoidCallback onBusiness;
  final VoidCallback onSitter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final children = [
          _PathCard(
            title: 'For vets & pet shops',
            price: '0–99 TND / month',
            items: const [
              'Listing and partner profile',
              'Featured discovery placement',
              'Offers, bundles, and care plans',
            ],
            onTap: onBusiness,
          ),
          _PathCard(
            title: 'For sitters',
            price: '0–19 TND / month',
            items: const [
              'Verified sitter badge',
              'Profile quality review',
              'Visibility based on activity',
            ],
            onTap: onSitter,
          ),
        ];

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 12),
              Expanded(child: children[1]),
            ],
          );
        }

        return Column(
          children: [children[0], const SizedBox(height: 12), children[1]],
        );
      },
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.title,
    required this.price,
    required this.items,
    required this.onTap,
  });

  final String title;
  final String price;
  final List<String> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
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
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              price,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.orangeDark,
              ),
            ),
            const SizedBox(height: 14),
            ...items.map((item) => _BulletLine(text: item)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppTheme.ink,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.8,
            fontWeight: FontWeight.w700,
            color: AppTheme.muted,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.badge,
    required this.benefits,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String price;
  final String period;
  final String badge;
  final List<String> benefits;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFFFFCF8) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: highlighted
                ? AppTheme.orange.withAlpha(120)
                : AppTheme.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                      height: 1.1,
                    ),
                  ),
                ),
                _Badge(label: badge),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    period,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...benefits.map((item) => _BulletLine(text: item)),
          ],
        ),
      ),
    );
  }
}

class _CommercialOptions extends StatelessWidget {
  const _CommercialOptions();

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
            'Partner options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 13),
          _DarkLine(
            title: 'Featured placement',
            body: 'Higher visibility in relevant city/category areas.',
          ),
          _DarkLine(
            title: 'Partner offers',
            body: 'Food, grooming, checkup, and accessory promotions.',
          ),
          _DarkLine(
            title: 'Care plans',
            body: 'Clinic or shop packages prepared for PetTounsi users.',
          ),
          _DarkLine(
            title: 'Activity review',
            body:
                'Sitter upgrades depend on requests, reviews, and profile quality.',
          ),
        ],
      ),
    );
  }
}

class _ApplyPanel extends StatelessWidget {
  const _ApplyPanel({required this.onBusiness, required this.onSitter});

  final VoidCallback onBusiness;
  final VoidCallback onSitter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start an application',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onBusiness,
                  child: const Text('Partner'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSitter,
                  child: const Text('Sitter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricingNote extends StatelessWidget {
  const _PricingNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Launch pricing. Final activation happens after PetTounsi review.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11.8,
        fontWeight: FontWeight.w700,
        color: AppTheme.muted,
        height: 1.25,
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                fontSize: 13,
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

class _DarkLine extends StatelessWidget {
  const _DarkLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEDE8EF),
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: '$title · ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(text: body),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.softOrange,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.orangeDark,
        ),
      ),
    );
  }
}
