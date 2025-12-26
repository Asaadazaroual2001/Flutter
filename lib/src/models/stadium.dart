import 'package:cloud_firestore/cloud_firestore.dart';

class Stadium {
  final String id;
  final String name;
  final String placeId; // relation to place
  final String city; // denormalized for easy filtering
  final String area; // quartier
  final String address;
  final double pricePerHour;
  final bool hasLights;
  final List<String> images;
  final DateTime createdAt;

  Stadium({
    required this.id,
    required this.name,
    required this.placeId,
    required this.city,
    required this.area,
    required this.address,
    required this.pricePerHour,
    required this.hasLights,
    required this.images,
    required this.createdAt,
  });

  factory Stadium.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Stadium(
      id: doc.id,
      name: data['name'] as String? ?? '',
      placeId: data['placeId'] as String? ?? '',
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      address: data['address'] as String? ?? '',
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      hasLights: data['hasLights'] as bool? ?? false,
      images: List<String>.from((data['images'] ?? const []) as List),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'placeId': placeId,
        'city': city,
        'area': area,
        'address': address,
        'pricePerHour': pricePerHour,
        'hasLights': hasLights,
        'images': images,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
