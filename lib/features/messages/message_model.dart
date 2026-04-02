import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/url_utils.dart';

class MessageModel {
  final String id;
  final String senderId;

  final String type; // 'text' | 'image'
  final String text;
  final String? imageUrl;

  final DateTime? createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
  });

  factory MessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();

    return MessageModel(
      id: doc.id,
      senderId: (d['senderId'] ?? '') as String,
      type: (d['type'] ?? 'text') as String,
      text: (d['text'] ?? '') as String,
      imageUrl: (d['imageUrl'] is String) ? UrlUtils.normalizeMediaUrl(d['imageUrl'] as String) : null,
      createdAt: dt,
    );
  }
}
