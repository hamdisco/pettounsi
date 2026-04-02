import 'package:flutter/material.dart';

import '../directory/directory_list_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DirectoryListPage(
      title: 'Events',
      collectionName: 'events',
      icon: Icons.event_outlined,
      emptyText: 'No events available yet.',
      accentColor: Color(0xFFF39A63),
      heroSubtitle: 'Adoption days, meetups, and pet-friendly activities near you.',
    );
  }
}
