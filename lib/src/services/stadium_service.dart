import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stadium.dart';
import '../utils/firestore_paths.dart';

class StadiumService {
  final FirebaseFirestore _db;
  StadiumService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Stadium>> stadiumsStream() {
    return _db
        .collection(FirestorePaths.stadiums())
        .snapshots()
        .map((s) => s.docs.map(Stadium.fromDoc).toList());
  }

  Future<void> upsertStadium(Stadium stadium) async {
    await _db.doc(FirestorePaths.stadium(stadium.id)).set(stadium.toMap());
  }
}
