import 'package:flutter/material.dart';

import '../directory/directory_list_page.dart';

class PetshopsPage extends StatelessWidget {
  const PetshopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DirectoryListPage(
      title: 'Pet Shops',
      collectionName: 'petshops',
      icon: Icons.storefront_rounded,
      emptyText: 'No pet shops yet.',
      accentColor: Color(0xFFE86C4F),
      heroSubtitle: 'Food, accessories, grooming, and trusted local pet stores.',
    );
  }
}
