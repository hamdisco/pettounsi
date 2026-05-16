import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../pet_babysitting/pet_babysitting_page.dart';
import '../petshops/petshops_page.dart';
import '../vets/vets_page.dart';
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
        const _HubHeader(),
        const SizedBox(height: 14),
        _UserServicesGrid(
          onSitters: () => _push(context, const PetBabysittingPage()),
          onVets: () => _push(context, const VetsPage()),
          onPetshops: () => _push(context, const PetshopsPage()),
        ),
        const SizedBox(height: 16),
        _PartnerEntryCard(
          onBusiness: () => _push(context, const PartnerApplicationPage()),
          onSitter: () => _push(context, const VerifiedSitterProgramPage()),
        ),
      ],
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pet services nearby',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
              height: 1.02,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find care, clinics, and trusted local shops in one place.',
            style: TextStyle(
              fontSize: 13.6,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserServicesGrid extends StatelessWidget {
  const _UserServicesGrid({
    required this.onSitters,
    required this.onVets,
    required this.onPetshops,
  });

  final VoidCallback onSitters;
  final VoidCallback onVets;
  final VoidCallback onPetshops;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final cards = [
          _ServiceTile(
            icon: Icons.pets_rounded,
            title: 'Pet sitting',
            body: 'Request trusted care for your pet.',
            actionLabel: 'Find sitters',
            color: AppTheme.softOrange,
            fg: AppTheme.orangeDark,
            onTap: onSitters,
          ),
          _ServiceTile(
            icon: Icons.local_hospital_rounded,
            title: 'Vets',
            body: 'Clinics, phone, WhatsApp, and directions.',
            actionLabel: 'Open vets',
            color: AppTheme.mint,
            fg: const Color(0xFF2F9A6A),
            onTap: onVets,
          ),
          _ServiceTile(
            icon: Icons.storefront_rounded,
            title: 'Pet shops',
            body: 'Food, grooming, accessories, and offers.',
            actionLabel: 'Open shops',
            color: AppTheme.butter,
            fg: const Color(0xFFB87900),
            onTap: onPetshops,
          ),
        ];

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.color,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final Color color;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.8,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.4,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              actionLabel,
              style: TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerEntryCard extends StatelessWidget {
  const _PartnerEntryCard({required this.onBusiness, required this.onSitter});

  final VoidCallback onBusiness;
  final VoidCallback onSitter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.orange.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handshake_rounded, color: AppTheme.orangeDark, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'For partners',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Clinics, shops, and sitters can request a reviewed profile.',
            style: TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onBusiness,
                  child: const Text('Business'),
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
