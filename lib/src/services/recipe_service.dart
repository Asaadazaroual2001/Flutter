import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';
import '../models/comment.dart';
import '../models/rating.dart';
import '../utils/firestore_paths.dart';

class RecipeService {
  final FirebaseFirestore _db;

  RecipeService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recipesCol =>
      _db.collection(FirestorePaths.recipes());

  Stream<List<Recipe>> recipesStream() {
    return _recipesCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Recipe.fromDoc).toList());
  }

  Stream<Recipe?> recipeByIdStream(String id) {
    return _recipesCol.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Recipe.fromDoc(doc);
    });
  }

  Future<String> createRecipe(Recipe recipe) async {
    final docRef = _recipesCol.doc();
    final newRecipe = recipe.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newRecipe.toMap());
    return docRef.id;
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _recipesCol.doc(recipe.id).update(
          recipe.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  Future<void> deleteRecipe(String id) async {
    await _recipesCol.doc(id).delete();
  }

  // Comments
  Stream<List<Comment>> commentsStream(String recipeId) {
    final col = _db.collection(FirestorePaths.comments(recipeId));
    return col.orderBy('createdAt').snapshots().map(
          (snap) => snap.docs.map(Comment.fromDoc).toList(),
        );
  }

  Future<void> addComment({
    required String recipeId,
    required String userId,
    required String text,
  }) async {
    final col = _db.collection(FirestorePaths.comments(recipeId));
    await col.add(Comment(
      id: '',
      userId: userId,
      text: text,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Future<void> editComment({
    required String recipeId,
    required String commentId,
    required String text,
  }) async {
    final doc =
        _db.collection(FirestorePaths.comments(recipeId)).doc(commentId);
    await doc.update({
      'text': text,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment({
    required String recipeId,
    required String commentId,
  }) async {
    final doc =
        _db.collection(FirestorePaths.comments(recipeId)).doc(commentId);
    await doc.delete();
  }

  // Ratings
  Future<void> rateRecipe({
    required String recipeId,
    required String userId,
    required int stars,
  }) async {
    final ratingRef =
        _db.collection(FirestorePaths.ratings(recipeId)).doc(userId);
    final recipeRef = _recipesCol.doc(recipeId);

    await _db.runTransaction((tx) async {
      final recipeSnap = await tx.get(recipeRef);
      if (!recipeSnap.exists || recipeSnap.data() == null) return;
      final recipe = Recipe.fromDoc(recipeSnap);

      final ratingSnap = await tx.get(ratingRef);
      int oldStars = 0;
      final bool isNew = !ratingSnap.exists;
      if (!isNew && ratingSnap.data() != null) {
        oldStars = (ratingSnap.data()!['stars'] as num?)?.toInt() ?? 0;
      }

      int newCount = recipe.ratingsCount;
      double totalStars = recipe.avgRating * recipe.ratingsCount;

      if (isNew) {
        newCount += 1;
        totalStars += stars;
      } else {
        totalStars = totalStars - oldStars + stars;
      }

      final newAvg = newCount == 0 ? 0.0 : totalStars / newCount;

      tx.set(
        ratingRef,
        Rating(userId: userId, stars: stars, createdAt: DateTime.now()).toMap(),
      );

      tx.update(recipeRef, {
        'ratingsCount': newCount,
        'avgRating': newAvg,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
