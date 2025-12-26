import 'package:cloud_firestore/cloud_firestore.dart';

class MatchParticipation {
  final String playerId;
  final String displayName;
  final String position;
  final String status;
  final String message;
  final DateTime createdAt;

  MatchParticipation({
    required this.playerId,
    required this.displayName,
    required this.position,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory MatchParticipation.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MatchParticipation(
      playerId: data['playerId'] as String? ?? doc.id,
      displayName: data['displayName'] as String? ??
          (data['playerId'] as String? ?? doc.id),
      position: data['position'] as String? ?? 'Any',
      status: data['status'] as String? ?? 'PENDING',
      message: data['message'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'displayName': displayName,
        'position': position,
        'status': status,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
