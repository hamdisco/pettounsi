import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/content_safety.dart';

class PetReportsRepository {
  PetReportsRepository._();
  static final PetReportsRepository instance = PetReportsRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('pet_reports');

  // -----------------------------
  // Public streams (optional/useful)
  // -----------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAll() {
    return _col.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMine() {
    final u = _auth.currentUser;
    if (u == null) {
      // Return an empty stream-like query result is not trivial, so use all + filter impossible.
      // In practice this method is called only when signed in.
      return const Stream.empty();
    }
    return _col
        .where('authorId', isEqualTo: u.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // -----------------------------
  // Create (main method)
  // -----------------------------
  /// Creates a lost/found pet report.
  ///
  /// Required:
  /// - type: "lost" or "found"
  /// - latitude / longitude
  ///
  /// Optional:
  /// - title, description, address, city, governorate, phone
  /// - photoUrl (or imageUrl), sourceUrl
  ///
  /// Returns new report document ID.
  Future<String> createReport({
    required String type, // "lost" | "found"
    required double latitude,
    required double longitude,
    String? title,
    String? description,
    String? address,
    String? city,
    String? governorate,
    String? animal,
    String? phone,
    String? photoUrl,
    String? imageUrl, // alias compatibility
    String? sourceUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final t = type.trim().toLowerCase();
    if (t != 'lost' && t != 'found') {
      throw Exception('Invalid report type. Use "lost" or "found".');
    }

    if (latitude < -90 || latitude > 90) {
      throw Exception('Invalid latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw Exception('Invalid longitude');
    }

    final cleanTitle = _clean(title, max: 120);
    final cleanDescription = _clean(description, max: 1200);
    final cleanAddress = _clean(address, max: 220);
    final cleanCity = _clean(city, max: 80);
    final cleanGovernorate = _clean(governorate, max: 80);
    final cleanAnimal = _clean(animal, max: 40);
    final cleanPhone = _clean(phone, max: 40);
    final cleanSourceUrl = _clean(sourceUrl, max: 500);
    ContentSafety.validatePublicText([
      cleanTitle,
      cleanDescription,
      cleanAnimal,
    ], context: 'pet report');
    final finalPhoto = _clean(photoUrl ?? imageUrl, max: 2000);

    final doc = _col.doc();

    await doc.set({
      'type': t, // lost | found
      'title': cleanTitle.isEmpty ? _defaultTitle(t, cleanAnimal) : cleanTitle,
      'description': cleanDescription,
      'address': cleanAddress,
      'city': cleanCity,
      'governorate': cleanGovernorate,
      'animal': cleanAnimal,

      // location (for robust compatibility)
      'geo': GeoPoint(latitude, longitude),
      'lat': latitude,
      'lng': longitude,

      // contact / links
      'phone': cleanPhone,
      'photoUrl': finalPhoto,
      'imageUrl': finalPhoto, // legacy compatibility
      'sourceUrl': cleanSourceUrl,

      // ownership
      'authorId': user.uid,
      'authorName': (user.displayName ?? 'User').trim(),
      'authorPhotoUrl': (user.photoURL ?? '').trim(),

      // status
      'status': 'open', // open | resolved
      'isResolved': false,

      // moderation/basic flags (future-safe)
      'isActive': true,

      // timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });

    return doc.id;
  }

  // -----------------------------
  // Backward-compatible aliases
  // (so your existing UI code is less likely to break)
  // -----------------------------
  Future<String> createPetReport({
    required String type,
    required double latitude,
    required double longitude,
    String? title,
    String? description,
    String? address,
    String? city,
    String? governorate,
    String? animal,
    String? phone,
    String? photoUrl,
    String? imageUrl,
    String? sourceUrl,
  }) {
    return createReport(
      type: type,
      latitude: latitude,
      longitude: longitude,
      title: title,
      description: description,
      address: address,
      city: city,
      governorate: governorate,
      animal: animal,
      phone: phone,
      photoUrl: photoUrl,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
    );
  }

  Future<String> createLostFoundReport({
    required String type,
    required double latitude,
    required double longitude,
    String? title,
    String? description,
    String? address,
    String? city,
    String? governorate,
    String? animal,
    String? phone,
    String? photoUrl,
    String? imageUrl,
    String? sourceUrl,
  }) {
    return createReport(
      type: type,
      latitude: latitude,
      longitude: longitude,
      title: title,
      description: description,
      address: address,
      city: city,
      governorate: governorate,
      animal: animal,
      phone: phone,
      photoUrl: photoUrl,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
    );
  }

  // -----------------------------
  // Status updates
  // -----------------------------
  Future<void> markResolved(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final ref = _col.doc(reportId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Report not found');

      final data = snap.data()!;
      final authorId = (data['authorId'] ?? '').toString();

      if (authorId != user.uid) {
        throw Exception('Not allowed');
      }

      final alreadyResolved =
          data['isResolved'] == true ||
          (data['status'] ?? '').toString().toLowerCase() == 'resolved';

      if (alreadyResolved) return;

      tx.update(ref, {
        'isResolved': true,
        'status': 'resolved',
        'updatedAt': FieldValue.serverTimestamp(),
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> reopenReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final ref = _col.doc(reportId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Report not found');

      final data = snap.data()!;
      final authorId = (data['authorId'] ?? '').toString();

      if (authorId != user.uid) {
        throw Exception('Not allowed');
      }

      tx.update(ref, {
        'isResolved': false,
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
      });
    });
  }

  // -----------------------------
  // Delete own report
  // -----------------------------
  Future<void> deleteReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final ref = _col.doc(reportId);
    final snap = await ref.get();

    if (!snap.exists) throw Exception('Report not found');

    final data = snap.data()!;
    final authorId = (data['authorId'] ?? '').toString();

    if (authorId != user.uid) {
      throw Exception('Not allowed');
    }

    await ref.delete();
  }

  // -----------------------------
  // Helpers
  // -----------------------------
  String _clean(String? value, {required int max}) {
    final s = (value ?? '').trim();
    if (s.isEmpty) return '';
    return s.length <= max ? s : s.substring(0, max);
  }

  String _defaultTitle(String type, String animal) {
    final t = type == 'lost' ? 'Lost Pet' : 'Found Pet';
    if (animal.isEmpty) return t;
    return '${type == 'lost' ? 'Lost' : 'Found'} $animal';
  }
}
