import 'package:cloud_firestore/cloud_firestore.dart';

class MatchMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // ORGANIZER | PLAYER
  final String text;
  final DateTime createdAt;

  MatchMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  factory MatchMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MatchMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Player',
      senderRole: data['senderRole'] as String? ?? 'PLAYER',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
