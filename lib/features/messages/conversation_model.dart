import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantNames;
  final Map<String, dynamic> participantPhotos;

  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, dynamic> lastReadAt; // uid -> Timestamp

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastReadAt,
  });

  factory ConversationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final parts = (d['participants'] is List)
        ? (d['participants'] as List).whereType<String>().toList()
        : <String>[];
    final ts = d['lastMessageAt'];
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();

    return ConversationModel(
      id: doc.id,
      participants: parts,
      participantNames: (d['participantNames'] is Map)
          ? Map<String, dynamic>.from(d['participantNames'])
          : {},
      participantPhotos: (d['participantPhotos'] is Map)
          ? Map<String, dynamic>.from(d['participantPhotos'])
          : {},
      lastMessage: (d['lastMessage'] ?? '') as String,
      lastMessageAt: dt,
      lastReadAt: (d['lastReadAt'] is Map)
          ? Map<String, dynamic>.from(d['lastReadAt'])
          : {},
    );
  }
}
