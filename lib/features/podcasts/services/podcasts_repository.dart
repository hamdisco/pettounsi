import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/podcast_episode.dart';

class PodcastsRepository {
  const PodcastsRepository();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('podcasts');

  Stream<List<PodcastEpisode>> watchPublished({int limit = 150}) {
    return _col
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(PodcastEpisode.fromDoc)
          .where((e) => e.isPublished)
          .toList();
    });
  }
}
