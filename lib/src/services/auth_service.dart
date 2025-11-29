import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../utils/firestore_paths.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user!.updateDisplayName(displayName);

    final userDoc = _db.collection(FirestorePaths.users()).doc(cred.user!.uid);
    final appUser = AppUser(
      id: cred.user!.uid,
      email: email,
      displayName: displayName,
      photoUrl: '',
      favorites: const [],
      createdAt: DateTime.now(),
    );

    await userDoc.set(appUser.toMap());
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<AppUser?> appUserStream(String userId) {
    final doc = _db.collection(FirestorePaths.users()).doc(userId);
    return doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AppUser.fromDoc(snap);
    });
  }

  // ⭐ CHANGED: safe toggleFavorite using set(..., merge: true)
  Future<void> toggleFavorite({
    required String userId,
    required String recipeId,
    required bool isFavorite,
  }) async {
    final userRef = _db.collection(FirestorePaths.users()).doc(userId);

    await userRef.set(
      {
        'favorites': isFavorite
            ? FieldValue.arrayRemove([recipeId])
            : FieldValue.arrayUnion([recipeId]),
      },
      SetOptions(merge: true),
    );
  }
}
