  import 'package:cloud_firestore/cloud_firestore.dart';

  class Ingredient {
    final String name;
    final String qty;

    Ingredient({
      required this.name,
      required this.qty,
    });

    Map<String, dynamic> toMap() => {
          'name': name,
          'qty': qty,
        };

    factory Ingredient.fromMap(Map<String, dynamic> map) {
      return Ingredient(
        name: map['name'] as String? ?? '',
        qty: map['qty'] as String? ?? '',
      );
    }
  }

  class Recipe {
    final String id;
    final String title;
    final String description;
    final String authorId;
    final String category;
    final String difficulty;
    final int prepTimeMin;
    final List<Ingredient> ingredients;
    final List<String> steps;
    final String imageUrl;
    final double avgRating;
    final int ratingsCount;
    final DateTime createdAt;
    final DateTime updatedAt;

    Recipe({
      required this.id,
      required this.title,
      required this.description,
      required this.authorId,
      required this.category,
      required this.difficulty,
      required this.prepTimeMin,
      required this.ingredients,
      required this.steps,
      required this.imageUrl,
      required this.avgRating,
      required this.ratingsCount,
      required this.createdAt,
      required this.updatedAt,
    });

    factory Recipe.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
      final data = doc.data()!;
      return Recipe(
        id: doc.id,
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        authorId: data['authorId'] as String? ?? '',
        category: data['category'] as String? ?? '',
        difficulty: data['difficulty'] as String? ?? '',
        prepTimeMin: (data['prepTimeMin'] as num?)?.toInt() ?? 0,
        ingredients: (data['ingredients'] as List<dynamic>? ?? [])
            .map((e) => Ingredient.fromMap(e as Map<String, dynamic>))
            .toList(),
        steps: List<String>.from(data['steps'] ?? []),
        imageUrl: data['imageUrl'] as String? ?? '',
        avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0.0,
        ratingsCount: (data['ratingsCount'] as num?)?.toInt() ?? 0,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'title': title,
        'description': description,
        'authorId': authorId,
        'category': category,
        'difficulty': difficulty,
        'prepTimeMin': prepTimeMin,
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        'steps': steps,
        'imageUrl': imageUrl,
        'avgRating': avgRating,
        'ratingsCount': ratingsCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
    }

    Recipe copyWith({
      String? id,
      String? title,
      String? description,
      String? authorId,
      String? category,
      String? difficulty,
      int? prepTimeMin,
      List<Ingredient>? ingredients,
      List<String>? steps,
      String? imageUrl,
      double? avgRating,
      int? ratingsCount,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      return Recipe(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        authorId: authorId ?? this.authorId,
        category: category ?? this.category,
        difficulty: difficulty ?? this.difficulty,
        prepTimeMin: prepTimeMin ?? this.prepTimeMin,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        imageUrl: imageUrl ?? this.imageUrl,
        avgRating: avgRating ?? this.avgRating,
        ratingsCount: ratingsCount ?? this.ratingsCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
    }
  }
