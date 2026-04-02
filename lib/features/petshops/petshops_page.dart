import 'package:flutter/material.dart';

import '../directory/directory_list_page.dart';

class PetshopsPage extends StatelessWidget {
  const PetshopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DirectoryListPage(
      title: 'Petshops',
      collectionName: 'petshops',
      icon: Icons.storefront_outlined,
      emptyText: 'No petshops available yet.',
      accentColor: Color(0xFF8E24AA),
      heroSubtitle: 'Food, accessories and grooming spots.',
    );
  }
}
