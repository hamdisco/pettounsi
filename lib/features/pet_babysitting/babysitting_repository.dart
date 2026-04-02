import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show DateTimeRange;

class BabysittingListing {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String title;
  final String description;
  final String city;
  final String governorate;
  final String priceText;
  final List<String> petTypes;
  final String availabilityText;
  final List<String> unavailableDateKeys;
  final List<String> bookedDateKeys;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BabysittingListing({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.title,
    required this.description,
    required this.city,
    required this.governorate,
    required this.priceText,
    required this.petTypes,
    required this.availabilityText,
    required this.unavailableDateKeys,
    required this.bookedDateKeys,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BabysittingListing.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return BabysittingListing(
      id: d.id,
      authorId: (m['authorId'] ?? '') as String,
      authorName: (m['authorName'] ?? 'User') as String,
      authorPhotoUrl: (m['authorPhotoUrl'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      city: (m['city'] ?? '') as String,
      governorate: (m['governorate'] ?? '') as String,
      priceText: (m['priceText'] ?? '') as String,
      petTypes: ((m['petTypes'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      availabilityText: (m['availabilityText'] ?? '') as String,
      unavailableDateKeys: babysittingNormalizeDateKeys(
        ((m['unavailableDateKeys'] as List?) ?? const []).map(
          (e) => e.toString(),
        ),
      ),
      bookedDateKeys: babysittingNormalizeDateKeys(
        ((m['bookedDateKeys'] as List?) ?? const []).map((e) => e.toString()),
      ),
      isActive: (m['isActive'] ?? true) == true,
      createdAt: _toDateTime(m['createdAt']),
      updatedAt: _toDateTime(m['updatedAt']),
    );
  }
}

class BabysittingRequestModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingOwnerId;
  final String listingOwnerName;

  final String requesterId;
  final String requesterName;
  final String requesterPhotoUrl;

  final String message;
  final String dateRangeText;
  final String status;
  final String conversationId;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> requestedDateKeys;
  final String startDateKey;
  final String endDateKey;

  const BabysittingRequestModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingOwnerId,
    required this.listingOwnerName,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhotoUrl,
    required this.message,
    required this.dateRangeText,
    required this.status,
    required this.conversationId,
    required this.createdAt,
    required this.updatedAt,
    required this.requestedDateKeys,
    required this.startDateKey,
    required this.endDateKey,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCompleted => status == 'completed';
  bool get isCanceled => status == 'canceled';

  factory BabysittingRequestModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final m = d.data() ?? {};
    return BabysittingRequestModel(
      id: d.id,
      listingId: (m['listingId'] ?? '') as String,
      listingTitle: (m['listingTitle'] ?? '') as String,
      listingOwnerId: (m['listingOwnerId'] ?? '') as String,
      listingOwnerName: (m['listingOwnerName'] ?? '') as String,
      requesterId: (m['requesterId'] ?? '') as String,
      requesterName: (m['requesterName'] ?? '') as String,
      requesterPhotoUrl: (m['requesterPhotoUrl'] ?? '') as String,
      message: (m['message'] ?? '') as String,
      dateRangeText: (m['dateRangeText'] ?? '') as String,
      status: (m['status'] ?? 'pending') as String,
      conversationId: (m['conversationId'] ?? '') as String,
      createdAt: _toDateTime(m['createdAt']),
      updatedAt: _toDateTime(m['updatedAt']),
      requestedDateKeys: babysittingNormalizeDateKeys(
        ((m['requestedDateKeys'] as List?) ?? const []).map(
          (e) => e.toString(),
        ),
        maxItems: 90,
      ),
      startDateKey: (m['startDateKey'] ?? '') as String,
      endDateKey: (m['endDateKey'] ?? '') as String,
    );
  }
}

class BabysittingReview {
  final String id;
  final String requestId;
  final String listingId;
  final String listingOwnerId;
  final String requesterId;
  final String requesterName;
  final String requesterPhotoUrl;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BabysittingReview({
    required this.id,
    required this.requestId,
    required this.listingId,
    required this.listingOwnerId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasComment => comment.trim().isNotEmpty;

  factory BabysittingReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final rawRating = m['rating'];
    final rating = rawRating is int
        ? rawRating
        : (rawRating is num ? rawRating.toInt() : 0);

    return BabysittingReview(
      id: d.id,
      requestId: (m['requestId'] ?? d.id).toString(),
      listingId: (m['listingId'] ?? '').toString(),
      listingOwnerId: (m['listingOwnerId'] ?? '').toString(),
      requesterId: (m['requesterId'] ?? '').toString(),
      requesterName: (m['requesterName'] ?? 'User').toString(),
      requesterPhotoUrl: (m['requesterPhotoUrl'] ?? '').toString(),
      rating: rating,
      comment: (m['comment'] ?? '').toString(),
      createdAt: _toDateTime(m['createdAt']),
      updatedAt: _toDateTime(m['updatedAt']),
    );
  }
}

class BabysitterRatingSummary {
  final int count;
  final double average;

  const BabysitterRatingSummary({required this.count, required this.average});

  static const empty = BabysitterRatingSummary(count: 0, average: 0);

  bool get hasReviews => count > 0;
}

DateTime? _toDateTime(dynamic v) {
  if (v is Timestamp) return v.toDate();
  return null;
}

bool _isDateKey(String v) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v);

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String babysittingDateKey(DateTime d) {
  final x = _dateOnly(d);
  final y = x.year.toString().padLeft(4, '0');
  final m = x.month.toString().padLeft(2, '0');
  final day = x.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime? babysittingDateFromKey(String key) {
  final s = key.trim();
  if (s.length != 10) return null;
  final parts = s.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  try {
    return DateTime(y, m, d);
  } catch (_) {
    return null;
  }
}

List<String> babysittingExpandDateRangeKeys(
  DateTimeRange range, {
  int maxDays = 90,
}) {
  final start = _dateOnly(range.start);
  final end = _dateOnly(range.end);
  if (end.isBefore(start)) return const [];

  final days = end.difference(start).inDays + 1;
  if (days <= 0 || days > maxDays) return const [];

  final out = <String>[];
  for (var i = 0; i < days; i++) {
    out.add(babysittingDateKey(start.add(Duration(days: i))));
  }
  return out;
}

List<String> babysittingNormalizeDateKeys(
  Iterable<String> keys, {
  int maxItems = 180,
}) {
  final set = <String>{};
  for (final k in keys) {
    final dt = babysittingDateFromKey(k);
    if (dt == null) continue;
    set.add(babysittingDateKey(dt));
    if (set.length >= maxItems) break;
  }
  final list = set.toList()..sort();
  return list;
}

bool babysittingRangeConflictsWithDateKeys(
  DateTimeRange range,
  Iterable<String> dateKeys,
) {
  final blocked = dateKeys.toSet();
  if (blocked.isEmpty) return false;
  for (final key in babysittingExpandDateRangeKeys(range)) {
    if (blocked.contains(key)) return true;
  }
  return false;
}

bool babysittingRangeConflictsWithUnavailable(
  DateTimeRange range,
  Iterable<String> unavailableDateKeys,
) {
  return babysittingRangeConflictsWithDateKeys(range, unavailableDateKeys);
}

class BabysittingRepository {
  BabysittingRepository._();
  static final BabysittingRepository instance = BabysittingRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('babysitting_listings');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('babysitting_requests');

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('babysitting_reviews');

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  User get _user {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not signed in');
    return u;
  }

  String _safeNameFromUser(User u) {
    final raw = (u.displayName ?? '').trim();
    return raw.isEmpty ? 'User' : raw;
  }

  String _safePhotoFromUser(User u) {
    return (u.photoURL ?? '').trim();
  }

  List<String> _cleanPetTypes(Iterable<String> values) {
    final out = <String>{};
    for (final raw in values) {
      final v = raw.trim().toLowerCase();
      if (v.isEmpty) continue;
      out.add(v);
    }
    return out.toList();
  }

  Future<void> _pushBabysittingNotification({
    required String toUid,
    required String type,
    required String actorUid,
    required String actorName,
    required String actorPhotoUrl,
    required String requestId,
    required String listingId,
    required String listingTitle,
    String dateRangeText = '',
    int? rating,
  }) async {
    final safeTo = toUid.trim();
    final safeActor = actorUid.trim();
    if (safeTo.isEmpty || safeActor.isEmpty || safeTo == safeActor) return;

    final payload = <String, dynamic>{
      'type': type,
      'toUid': safeTo,
      'actorUid': safeActor,
      'actorName': actorName.trim().isEmpty ? 'User' : actorName.trim(),
      'actorPhotoUrl': actorPhotoUrl.trim(),
      'requestId': requestId.trim(),
      'listingId': listingId.trim(),
      'listingTitle': listingTitle.trim(),
      'dateRangeText': dateRangeText.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    };

    if (rating != null) payload['rating'] = rating;

    await _db
        .collection('notifications')
        .doc(safeTo)
        .collection('items')
        .add(payload);
  }

  Stream<List<BabysittingListing>> streamActiveListings({int limit = 100}) {
    return _listings
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(BabysittingListing.fromDoc).toList());
  }

  Stream<List<BabysittingListing>> streamMyListings({int limit = 100}) {
    final uid = _user.uid;

    return _listings
        .where('authorId', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map((s) {
          final list = s.docs.map(BabysittingListing.fromDoc).toList();
          list.sort((a, b) {
            final ad = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });
          return list;
        });
  }

  Stream<List<BabysittingRequestModel>> streamIncomingRequests({
    int limit = 100,
  }) {
    final uid = _user.uid;

    return _requests
        .where('listingOwnerId', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map((s) {
          final list = s.docs.map(BabysittingRequestModel.fromDoc).toList();
          list.sort((a, b) {
            final ad = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });
          return list;
        });
  }

  Stream<List<BabysittingRequestModel>> streamOutgoingRequests({
    int limit = 100,
  }) {
    final uid = _user.uid;

    return _requests
        .where('requesterId', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map((s) {
          final list = s.docs.map(BabysittingRequestModel.fromDoc).toList();
          list.sort((a, b) {
            final ad = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });
          return list;
        });
  }

  Future<void> createListing({
    required String title,
    required String description,
    required String city,
    required String governorate,
    required String priceText,
    required List<String> petTypes,
    required String availabilityText,
    List<String> unavailableDateKeys = const [],
  }) async {
    final u = _user;
    final now = FieldValue.serverTimestamp();

    await _listings.doc().set({
      'authorId': u.uid,
      'authorName': _safeNameFromUser(u),
      'authorPhotoUrl': _safePhotoFromUser(u),
      'title': title.trim(),
      'description': description.trim(),
      'city': city.trim(),
      'governorate': governorate.trim(),
      'priceText': priceText.trim(),
      'petTypes': _cleanPetTypes(petTypes),
      'availabilityText': availabilityText.trim(),
      'unavailableDateKeys': babysittingNormalizeDateKeys(unavailableDateKeys),
      'isActive': true,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateListing({
    required String listingId,
    required String title,
    required String description,
    required String city,
    required String governorate,
    required String priceText,
    required List<String> petTypes,
    required String availabilityText,
    required bool isActive,
    List<String>? unavailableDateKeys,
  }) async {
    final u = _user;

    await _listings.doc(listingId).update({
      'authorId': u.uid,
      'authorName': _safeNameFromUser(u),
      'authorPhotoUrl': _safePhotoFromUser(u),
      'title': title.trim(),
      'description': description.trim(),
      'city': city.trim(),
      'governorate': governorate.trim(),
      'priceText': priceText.trim(),
      'petTypes': _cleanPetTypes(petTypes),
      'availabilityText': availabilityText.trim(),
      if (unavailableDateKeys != null)
        'unavailableDateKeys': babysittingNormalizeDateKeys(
          unavailableDateKeys,
        ),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleListingActive(String listingId, bool isActive) async {
    final u = _user;

    await _listings.doc(listingId).update({
      'authorId': u.uid,
      'authorName': _safeNameFromUser(u),
      'authorPhotoUrl': _safePhotoFromUser(u),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteListing(String listingId) async {
    await _listings.doc(listingId).delete();
  }

  Future<void> createRequest({
    required BabysittingListing listing,
    required String message,
    required String dateRangeText,
    List<String> requestedDateKeys = const [],
    String? startDateKey,
    String? endDateKey,
  }) async {
    final u = _user;

    if (listing.authorId == u.uid) {
      throw Exception("You can't request your own listing");
    }

    final cleanMsg = message.trim();
    final cleanDates = dateRangeText.trim();

    if (cleanMsg.isEmpty) throw Exception('Message is required');
    if (cleanDates.isEmpty) throw Exception('Date range is required');

    final normalizedRequestedDateKeys = babysittingNormalizeDateKeys(
      requestedDateKeys,
      maxItems: 90,
    );

    final ref = _requests.doc();

    await ref.set({
      'listingId': listing.id,
      'listingTitle': listing.title,
      'listingOwnerId': listing.authorId,
      'listingOwnerName': listing.authorName,
      'requesterId': u.uid,
      'requesterName': _safeNameFromUser(u),
      'requesterPhotoUrl': _safePhotoFromUser(u),
      'message': cleanMsg,
      'dateRangeText': cleanDates,
      'status': 'pending',
      'conversationId': '',
      'requestedDateKeys': normalizedRequestedDateKeys,
      'startDateKey': _isDateKey(startDateKey ?? '')
          ? startDateKey
          : (normalizedRequestedDateKeys.isNotEmpty
                ? normalizedRequestedDateKeys.first
                : ''),
      'endDateKey': _isDateKey(endDateKey ?? '')
          ? endDateKey
          : (normalizedRequestedDateKeys.isNotEmpty
                ? normalizedRequestedDateKeys.last
                : ''),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _pushBabysittingNotification(
      toUid: listing.authorId,
      type: 'babysitting_request',
      actorUid: u.uid,
      actorName: _safeNameFromUser(u),
      actorPhotoUrl: _safePhotoFromUser(u),
      requestId: ref.id,
      listingId: listing.id,
      listingTitle: listing.title,
      dateRangeText: cleanDates,
    );
  }

  Future<String> acceptRequest(BabysittingRequestModel req) async {
    return acceptRequestAndBlockDates(req);
  }

  Future<String> acceptRequestAndBlockDates(BabysittingRequestModel req) async {
    final u = _user;
    if (u.uid != req.listingOwnerId) throw Exception('Not allowed');

    final convId = await _createOrGetConversation(
      aUid: req.listingOwnerId,
      bUid: req.requesterId,
      aName: req.listingOwnerName,
      bName: req.requesterName,
    );

    final reqRef = _requests.doc(req.id);
    final listingRef = _listings.doc(req.listingId);

    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      final listingSnap = await tx.get(listingRef);

      if (!reqSnap.exists) throw Exception('Request not found');
      if (!listingSnap.exists) throw Exception('Listing not found');

      final reqData = reqSnap.data() ?? <String, dynamic>{};
      final listingData = listingSnap.data() ?? <String, dynamic>{};

      final status = (reqData['status'] ?? '').toString();
      if (status != 'pending') {
        throw Exception('Request is no longer pending');
      }

      final ownerId = (reqData['listingOwnerId'] ?? '').toString();
      if (ownerId != u.uid) throw Exception('Unauthorized');

      final requested = babysittingNormalizeDateKeys(
        ((reqData['requestedDateKeys'] as List?) ?? const []).map(
          (e) => e.toString(),
        ),
        maxItems: 90,
      );

      final unavailable = babysittingNormalizeDateKeys(
        ((listingData['unavailableDateKeys'] as List?) ?? const []).map(
          (e) => e.toString(),
        ),
        maxItems: 365,
      ).toSet();

      if (requested.isNotEmpty) {
        final hasOverlap = requested.any(unavailable.contains);
        if (hasOverlap) {
          throw Exception(
            'These dates are no longer available. Please ask for another date range.',
          );
        }

        unavailable.addAll(requested);

        tx.update(listingRef, {
          'unavailableDateKeys': unavailable.toList()..sort(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(reqRef, {
        'status': 'accepted',
        'conversationId': convId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _pushBabysittingNotification(
      toUid: req.requesterId,
      type: 'babysitting_accepted',
      actorUid: req.listingOwnerId,
      actorName: req.listingOwnerName,
      actorPhotoUrl: '',
      requestId: req.id,
      listingId: req.listingId,
      listingTitle: req.listingTitle,
      dateRangeText: req.dateRangeText,
    );

    return convId;
  }

  Future<void> declineRequest(BabysittingRequestModel req) async {
    final u = _user;
    if (u.uid != req.listingOwnerId) throw Exception('Not allowed');

    await _requests.doc(req.id).update({
      'status': 'declined',
      'conversationId': req.conversationId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _pushBabysittingNotification(
      toUid: req.requesterId,
      type: 'babysitting_declined',
      actorUid: req.listingOwnerId,
      actorName: req.listingOwnerName,
      actorPhotoUrl: '',
      requestId: req.id,
      listingId: req.listingId,
      listingTitle: req.listingTitle,
      dateRangeText: req.dateRangeText,
    );
  }

  Future<void> completeRequest(BabysittingRequestModel req) async {
    final u = _user;
    if (u.uid != req.listingOwnerId) throw Exception('Not allowed');

    await _requests.doc(req.id).update({
      'status': 'completed',
      'conversationId': req.conversationId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _pushBabysittingNotification(
      toUid: req.requesterId,
      type: 'babysitting_completed',
      actorUid: req.listingOwnerId,
      actorName: req.listingOwnerName,
      actorPhotoUrl: '',
      requestId: req.id,
      listingId: req.listingId,
      listingTitle: req.listingTitle,
      dateRangeText: req.dateRangeText,
    );
  }

  Future<void> cancelRequest(BabysittingRequestModel req) async {
    final u = _user;
    if (u.uid != req.requesterId) throw Exception('Not allowed');

    await _requests.doc(req.id).update({
      'status': 'canceled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _pushBabysittingNotification(
      toUid: req.listingOwnerId,
      type: 'babysitting_canceled',
      actorUid: req.requesterId,
      actorName: req.requesterName,
      actorPhotoUrl: req.requesterPhotoUrl,
      requestId: req.id,
      listingId: req.listingId,
      listingTitle: req.listingTitle,
      dateRangeText: req.dateRangeText,
    );
  }

  Stream<bool> streamHasReviewedRequest(String requestId) {
    return _reviews.doc(requestId).snapshots().map((d) => d.exists);
  }

  Stream<List<Map<String, dynamic>>> streamListingReviews(
    String listingId, {
    int limit = 20,
  }) {
    return _reviews
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<BabysittingReview>> streamListingReviewModels(
    String listingId, {
    int limit = 20,
  }) {
    final id = listingId.trim();
    if (id.isEmpty) return Stream.value(const []);

    return _reviews
        .where('listingId', isEqualTo: id)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(BabysittingReview.fromDoc).toList());
  }

  Stream<List<BabysittingReview>> streamSitterReviewModels(
    String sitterUid, {
    int limit = 20,
  }) {
    final uid = sitterUid.trim();
    if (uid.isEmpty) return Stream.value(const []);

    return _reviews
        .where('listingOwnerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(BabysittingReview.fromDoc).toList());
  }

  Future<void> submitReviewForCompletedRequest({
    required BabysittingRequestModel req,
    required int rating,
    required String comment,
  }) async {
    final u = _user;

    if (u.uid != req.requesterId) {
      throw Exception('Only requester can review');
    }
    if (!req.isCompleted) {
      throw Exception('Request must be completed first');
    }
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    final cleanComment = comment.trim();
    if (cleanComment.length > 500) {
      throw Exception('Comment is too long');
    }

    await _reviews.doc(req.id).set({
      'requestId': req.id,
      'listingId': req.listingId,
      'listingOwnerId': req.listingOwnerId,
      'requesterId': req.requesterId,
      'requesterName': req.requesterName,
      'requesterPhotoUrl': req.requesterPhotoUrl,
      'rating': rating,
      'comment': cleanComment,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _pushBabysittingNotification(
      toUid: req.listingOwnerId,
      type: 'babysitting_review',
      actorUid: req.requesterId,
      actorName: req.requesterName,
      actorPhotoUrl: req.requesterPhotoUrl,
      requestId: req.id,
      listingId: req.listingId,
      listingTitle: req.listingTitle,
      dateRangeText: req.dateRangeText,
      rating: rating,
    );
  }

  Stream<BabysitterRatingSummary> streamSitterRatingSummary(
    String sitterUid, {
    int limit = 200,
  }) {
    final uid = sitterUid.trim();
    if (uid.isEmpty) {
      return Stream.value(BabysitterRatingSummary.empty);
    }

    return _reviews
        .where('listingOwnerId', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map((s) => _ratingSummaryFromReviewDocs(s.docs));
  }

  Stream<BabysitterRatingSummary> streamListingRatingSummary(
    String listingId, {
    int limit = 200,
  }) {
    final id = listingId.trim();
    if (id.isEmpty) {
      return Stream.value(BabysitterRatingSummary.empty);
    }

    return _reviews
        .where('listingId', isEqualTo: id)
        .limit(limit)
        .snapshots()
        .map((s) => _ratingSummaryFromReviewDocs(s.docs));
  }

  BabysitterRatingSummary _ratingSummaryFromReviewDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var count = 0;
    var total = 0.0;

    for (final d in docs) {
      final m = d.data();
      final raw = m['rating'];

      int? rating;
      if (raw is int) {
        rating = raw;
      } else if (raw is num) {
        rating = raw.toInt();
      }

      if (rating == null) continue;
      if (rating < 1 || rating > 5) continue;

      count += 1;
      total += rating;
    }

    if (count == 0) return BabysitterRatingSummary.empty;

    return BabysitterRatingSummary(count: count, average: total / count);
  }

  Future<String> _createOrGetConversation({
    required String aUid,
    required String bUid,
    required String aName,
    required String bName,
  }) async {
    final ids = [aUid, bUid]..sort();
    final convId = 'dm_${ids[0]}_${ids[1]}';

    final ref = _conversations.doc(convId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'participants': ids,
        'participantNames': {
          ids[0]: ids[0] == aUid ? aName : bName,
          ids[1]: ids[1] == aUid ? aName : bName,
        },
        'lastMessage': '',
        'lastMessageType': 'system',
        'lastSenderId': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({'updatedAt': FieldValue.serverTimestamp()});
    }

    return convId;
  }
}
