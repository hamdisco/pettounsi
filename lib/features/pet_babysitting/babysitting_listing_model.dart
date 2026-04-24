import 'package:cloud_firestore/cloud_firestore.dart';

class BabysittingListingModel {
  const BabysittingListingModel({
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
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

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

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BabysittingListingModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data() ?? <String, dynamic>{};

    List<String> readStringList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    DateTime? readDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    String readStr(String key, [String fallback = '']) {
      final v = m[key];
      if (v == null) return fallback;
      final s = v.toString().trim();
      return s.isEmpty ? fallback : s;
    }

    return BabysittingListingModel(
      id: doc.id,
      authorId: readStr('authorId'),
      authorName: readStr('authorName', 'User'),
      authorPhotoUrl: readStr('authorPhotoUrl'),
      title: readStr('title', 'Pet Sitter'),
      description: readStr('description'),
      city: readStr('city'),
      governorate: readStr('governorate'),
      priceText: readStr('priceText'),
      petTypes: readStringList(m['petTypes']),
      availabilityText: readStr('availabilityText'),
      isActive: m['isActive'] is bool ? m['isActive'] as bool : true,
      createdAt: readDate(m['createdAt']),
      updatedAt: readDate(m['updatedAt']),
    );
  }
}
