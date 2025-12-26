import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe.dart';
import '../models/comment.dart';
import '../services/recipe_service.dart';
import 'filter_providers.dart';

final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService();
});

final recipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final service = ref.watch(recipeServiceProvider);
  return service.recipesStream();
});

final recipeByIdProvider =
    StreamProvider.family<Recipe?, String>((ref, recipeId) {
  final service = ref.watch(recipeServiceProvider);
  return service.recipeByIdStream(recipeId);
});

final commentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, recipeId) {
  final service = ref.watch(recipeServiceProvider);
  return service.commentsStream(recipeId);
});

/// Returns the list of recipes filtered by:
/// - search query (title / description / ingredients)
/// - category
/// - difficulty
/// - max prep time
final filteredRecipesProvider = Provider<List<Recipe>>((ref) {
  final recipesAsync = ref.watch(recipesStreamProvider);

  // IMPORTANT: use watch (not read) so this recomputes when filters change
  final rawQuery = ref.watch(searchQueryProvider);
  final rawDifficulty = ref.watch(difficultyFilterProvider);
  final maxPrep = ref.watch(maxPrepTimeFilterProvider);
  final rawCategory = ref.watch(categoryFilterProvider);

  // Normalize filters
  final query = rawQuery.trim().toLowerCase();
  final difficulty = rawDifficulty?.trim();
  final normalizedCategory = rawCategory?.trim().toLowerCase();

  return recipesAsync.maybeWhen(
    data: (recipes) {
      return recipes.where((recipe) {
        // ----- SEARCH -----
        bool matchesSearch = true;
        if (query.isNotEmpty) {
          final inTitle = recipe.title.toLowerCase().contains(query);
          final inDescription =
              recipe.description.toLowerCase().contains(query);
          final inIngredients = recipe.ingredients.any((ing) {
            final name = ing.name.toLowerCase();
            final qty = ing.qty.toLowerCase();
            return name.contains(query) || qty.contains(query);
          });

          matchesSearch = inTitle || inDescription || inIngredients;
        }

        // ----- CATEGORY FILTER (case-insensitive, trimmed) -----
        bool matchesCategory = true;
        if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
          final recipeCategory = recipe.category.trim().toLowerCase();
          matchesCategory = recipeCategory == normalizedCategory;
        }

        // ----- DIFFICULTY FILTER -----
        bool matchesDifficulty = true;
        if (difficulty != null && difficulty.isNotEmpty) {
          matchesDifficulty = recipe.difficulty == difficulty;
        }

        // ----- PREP TIME FILTER -----
        final bool matchesPrepTime =
            maxPrep == null || recipe.prepTimeMin <= maxPrep;

        return matchesSearch &&
            matchesCategory &&
            matchesDifficulty &&
            matchesPrepTime;
      }).toList();
    },
    orElse: () => <Recipe>[],
  );
});
