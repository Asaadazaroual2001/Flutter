import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';
import '../utils/firestore_paths.dart';

class PlaceService {
  final FirebaseFirestore _db;
  PlaceService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Place>> placesStream() {
    return _db
        .collection(FirestorePaths.places())
        .orderBy('city')
        .orderBy('area')
        .snapshots()
        .map((s) => s.docs.map(Place.fromDoc).toList());
  }

  Future<void> upsertPlace(Place place) async {
    await _db.doc(FirestorePaths.place(place.id)).set(place.toMap());
  }
}
