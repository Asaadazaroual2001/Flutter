import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String city;
  final String area;

  Place({required this.id, required this.city, required this.area});

  factory Place.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Place(
      id: doc.id,
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'city': city,
        'area': area,
      };
}
