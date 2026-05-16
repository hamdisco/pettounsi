import 'package:flutter/material.dart';

import '../directory/directory_list_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DirectoryListPage(
      title: 'Pet Events',
      collectionName: 'events',
      icon: Icons.event_rounded,
      emptyText: 'No upcoming pet events yet.',
      accentColor: Color(0xFF7C62D7),
      heroSubtitle: 'Adoption days, meetups, and local pet activities.',
    );
  }
}
