import 'package:flutter/material.dart';

import '../directory/directory_list_page.dart';

class VetsPage extends StatelessWidget {
  const VetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DirectoryListPage(
      title: 'Vets',
      collectionName: 'vets',
      icon: Icons.local_hospital_outlined,
      emptyText: 'No vets available yet.',
      accentColor: Color(0xFF2FAE79),
      heroSubtitle: 'Clinics, emergency care, and trusted veterinarians.',
    );
  }
}
