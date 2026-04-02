import 'package:cloud_firestore/cloud_firestore.dart';

int pointsAsInt(Object? value) {
  if (value is num) return value.toInt();
  return 0;
}

String lowerStatus(Map<String, dynamic> data) {
  return (data['status'] ?? '').toString().trim().toLowerCase();
}

int approvedClaimPointsFromSnapshots(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
) {
  var total = 0;
  for (final doc in docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
    final data = doc.data();
    if (lowerStatus(data) != 'approved') continue;
    total += pointsAsInt(data['missionReward']);
  }
  return total;
}

bool redemptionReservesPoints(String status) {
  return status == 'pending' || status == 'approved' || status == 'fulfilled';
}

int reservedRedemptionPointsFromSnapshots(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
) {
  var total = 0;
  for (final doc in docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
    final data = doc.data();
    if (!redemptionReservesPoints(lowerStatus(data))) continue;
    total += pointsAsInt(data['pointsCost']);
  }
  return total;
}

/// Source of truth for game-earned points.
///
/// If the user has any approved game claims, trust the approved claims total.
/// Otherwise fall back to the legacy synced balance on the user document.
int officialPointsFromData({
  required int syncedPoints,
  required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>? claimDocs,
}) {
  final approvedTotal = approvedClaimPointsFromSnapshots(claimDocs);
  if (approvedTotal > 0) return approvedTotal;
  return syncedPoints;
}
