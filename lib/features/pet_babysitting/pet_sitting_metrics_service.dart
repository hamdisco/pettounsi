import 'package:cloud_firestore/cloud_firestore.dart';

class PetSittingMetricsSummary {
  const PetSittingMetricsSummary({
    required this.listingCreatedCount,
    required this.requestCreatedCount,
    required this.requestAcceptedCount,
    required this.requestDeclinedCount,
    required this.requestCanceledCount,
    required this.stayCompletedCount,
    required this.reviewCount,
    required this.ratingTotal,
    required this.lastUpdatedAt,
  });

  final int listingCreatedCount;
  final int requestCreatedCount;
  final int requestAcceptedCount;
  final int requestDeclinedCount;
  final int requestCanceledCount;
  final int stayCompletedCount;
  final int reviewCount;
  final int ratingTotal;
  final DateTime? lastUpdatedAt;

  double get averageRating => reviewCount == 0 ? 0 : ratingTotal / reviewCount;

  factory PetSittingMetricsSummary.fromMap(Map<String, dynamic> data) {
    return PetSittingMetricsSummary(
      listingCreatedCount: _readInt(data['listingCreatedCount']),
      requestCreatedCount: _readInt(data['requestCreatedCount']),
      requestAcceptedCount: _readInt(data['requestAcceptedCount']),
      requestDeclinedCount: _readInt(data['requestDeclinedCount']),
      requestCanceledCount: _readInt(data['requestCanceledCount']),
      stayCompletedCount: _readInt(data['stayCompletedCount']),
      reviewCount: _readInt(data['reviewCount']),
      ratingTotal: _readInt(data['ratingTotal']),
      lastUpdatedAt: _readDate(data['lastUpdatedAt']),
    );
  }

  static const empty = PetSittingMetricsSummary(
    listingCreatedCount: 0,
    requestCreatedCount: 0,
    requestAcceptedCount: 0,
    requestDeclinedCount: 0,
    requestCanceledCount: 0,
    stayCompletedCount: 0,
    reviewCount: 0,
    ratingTotal: 0,
    lastUpdatedAt: null,
  );
}

class PetSittingMetricsService {
  PetSittingMetricsService._();
  static final PetSittingMetricsService instance = PetSittingMetricsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _summaryRef =>
      _db.collection('pet_sitting_metrics').doc('summary');

  CollectionReference<Map<String, dynamic>> get _dailyCollection =>
      _db.collection('pet_sitting_metrics_daily');

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _db.collection('pet_sitting_metric_events');

  Stream<PetSittingMetricsSummary> streamSummary() {
    return _summaryRef.snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return PetSittingMetricsSummary.empty;
      return PetSittingMetricsSummary.fromMap(data);
    });
  }

  Future<void> trackListingCreated({
    required String listingId,
    required String sitterUid,
    required String city,
    required String governorate,
    required List<String> petTypes,
  }) async {
    await _safeTrack(
      eventType: 'listing_created',
      summaryIncrements: const {'listingCreatedCount': 1},
      dailyIncrements: const {'listingCreatedCount': 1},
      eventData: {
        'listingId': listingId,
        'sitterUid': sitterUid,
        'city': city.trim(),
        'governorate': governorate.trim(),
        'petTypes': petTypes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      },
    );
  }

  Future<void> trackRequestCreated({
    required String requestId,
    required String listingId,
    required String sitterUid,
    required String requesterUid,
    required String city,
    required String governorate,
    required int requestedDayCount,
  }) async {
    await _safeTrack(
      eventType: 'request_created',
      summaryIncrements: const {'requestCreatedCount': 1},
      dailyIncrements: const {'requestCreatedCount': 1},
      eventData: {
        'requestId': requestId,
        'listingId': listingId,
        'sitterUid': sitterUid,
        'requesterUid': requesterUid,
        'city': city.trim(),
        'governorate': governorate.trim(),
        'requestedDayCount': requestedDayCount,
      },
    );
  }

  Future<void> trackRequestStatusChanged({
    required String requestId,
    required String listingId,
    required String sitterUid,
    required String requesterUid,
    required String status,
  }) async {
    final normalized = status.trim().toLowerCase();
    final field = switch (normalized) {
      'accepted' => 'requestAcceptedCount',
      'declined' => 'requestDeclinedCount',
      'canceled' => 'requestCanceledCount',
      'completed' => 'stayCompletedCount',
      _ => 'requestStatusChangedCount',
    };

    await _safeTrack(
      eventType: 'request_$normalized',
      summaryIncrements: {field: 1},
      dailyIncrements: {field: 1},
      eventData: {
        'requestId': requestId,
        'listingId': listingId,
        'sitterUid': sitterUid,
        'requesterUid': requesterUid,
        'status': normalized,
      },
    );
  }

  Future<void> trackReviewPublished({
    required String requestId,
    required String listingId,
    required String sitterUid,
    required String requesterUid,
    required int rating,
  }) async {
    final safeRating = rating.clamp(1, 5).toInt();
    await _safeTrack(
      eventType: 'review_published',
      summaryIncrements: {
        'reviewCount': 1,
        'ratingTotal': safeRating,
      },
      dailyIncrements: {
        'reviewCount': 1,
        'ratingTotal': safeRating,
      },
      eventData: {
        'requestId': requestId,
        'listingId': listingId,
        'sitterUid': sitterUid,
        'requesterUid': requesterUid,
        'rating': safeRating,
      },
    );
  }

  Future<void> _safeTrack({
    required String eventType,
    required Map<String, int> summaryIncrements,
    required Map<String, int> dailyIncrements,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final now = DateTime.now();
      final dayKey = _dayKey(now);
      final dailyRef = _dailyCollection.doc(dayKey);
      final eventRef = _eventsCollection.doc();
      final writeTime = FieldValue.serverTimestamp();

      final summaryUpdate = <String, dynamic>{
        for (final entry in summaryIncrements.entries)
          entry.key: FieldValue.increment(entry.value),
        'lastEventType': eventType,
        'lastUpdatedAt': writeTime,
      };

      final dailyUpdate = <String, dynamic>{
        for (final entry in dailyIncrements.entries)
          entry.key: FieldValue.increment(entry.value),
        'dateKey': dayKey,
        'lastEventType': eventType,
        'lastUpdatedAt': writeTime,
      };

      final event = <String, dynamic>{
        'eventType': eventType,
        'dateKey': dayKey,
        ...eventData,
        'createdAt': writeTime,
      };

      final batch = _db.batch();
      batch.set(_summaryRef, summaryUpdate, SetOptions(merge: true));
      batch.set(dailyRef, dailyUpdate, SetOptions(merge: true));
      batch.set(eventRef, event);
      await batch.commit();
    } catch (_) {
      // Metrics must never block core booking/listing/review flows.
    }
  }

  static String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  return null;
}
