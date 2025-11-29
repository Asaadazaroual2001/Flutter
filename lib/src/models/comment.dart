import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final DateTime? editedAt;

  Comment({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.editedAt,
  });

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Comment(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
    };
  }
}
