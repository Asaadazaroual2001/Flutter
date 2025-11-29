import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String userId;
  final int stars;
  final DateTime createdAt;

  Rating({
    required this.userId,
    required this.stars,
    required this.createdAt,
  });

  factory Rating.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Rating(
      userId: data['userId'] as String? ?? '',
      stars: (data['stars'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'stars': stars,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
