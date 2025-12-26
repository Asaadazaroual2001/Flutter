import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final List<String> favorites;
  final DateTime createdAt;

  // ✅ EXTRA INFO (optional)
  final DateTime? birthDate;
  final int? age;
  final String? city;
  final String? phone;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.favorites,
    required this.createdAt,
    this.birthDate,
    this.age,
    this.city,
    this.phone,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? birthDate;
    final bd = data['birthDate'];
    if (bd is Timestamp) birthDate = bd.toDate();

    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      favorites: List<String>.from(data['favorites'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // ✅ extra
      birthDate: birthDate,
      age: (data['age'] is int)
          ? data['age'] as int
          : int.tryParse('${data['age']}'),
      city: data['city'] as String?,
      phone: data['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'favorites': favorites,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // ✅ only add if not null
    if (birthDate != null) map['birthDate'] = Timestamp.fromDate(birthDate!);
    if (age != null) map['age'] = age;
    if (city != null) map['city'] = city;
    if (phone != null) map['phone'] = phone;

    return map;
  }
}
