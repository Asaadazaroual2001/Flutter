import 'package:cloud_firestore/cloud_firestore.dart';

class MatchAnnouncement {
  final String id;
  final String organizerId;

  final String stadiumId;
  final String stadiumName; // denormalized
  final String city; // denormalized
  final String area; // denormalized

  final DateTime startAt; // date+time
  final int durationMin;

  final int totalPlayersNeeded;
  final int acceptedCount;

  final List<String> positionsNeeded; // ["GK","DF",...]
  final String notes;

  final String status; // OPEN / FULL / CANCELED
  final DateTime createdAt;
  final DateTime updatedAt;

  MatchAnnouncement({
    required this.id,
    required this.organizerId,
    required this.stadiumId,
    required this.stadiumName,
    required this.city,
    required this.area,
    required this.startAt,
    required this.durationMin,
    required this.totalPlayersNeeded,
    required this.acceptedCount,
    required this.positionsNeeded,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchAnnouncement.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MatchAnnouncement(
      id: doc.id,
      organizerId: data['organizerId'] as String? ?? '',
      stadiumId: data['stadiumId'] as String? ?? '',
      stadiumName: data['stadiumName'] as String? ?? '',
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      startAt: (data['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMin: (data['durationMin'] as num?)?.toInt() ?? 60,
      totalPlayersNeeded: (data['totalPlayersNeeded'] as num?)?.toInt() ?? 10,
      acceptedCount: (data['acceptedCount'] as num?)?.toInt() ?? 0,
      positionsNeeded: List<String>.from(data['positionsNeeded'] ?? const []),
      notes: data['notes'] as String? ?? '',
      status: data['status'] as String? ?? 'OPEN',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'organizerId': organizerId,
        'stadiumId': stadiumId,
        'stadiumName': stadiumName,
        'city': city,
        'area': area,
        'startAt': Timestamp.fromDate(startAt),
        'durationMin': durationMin,
        'totalPlayersNeeded': totalPlayersNeeded,
        'acceptedCount': acceptedCount,
        'positionsNeeded': positionsNeeded,
        'notes': notes,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  int get missingPlayers => (totalPlayersNeeded - acceptedCount).clamp(0, 9999);
}
