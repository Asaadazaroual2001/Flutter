import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../widgets/recipe_card.dart';

class MyRecipesScreen extends ConsumerWidget {
  static const routeName = '/my-recipes';

  const MyRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final recipesAsync = ref.watch(recipesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
      ),
      body: recipesAsync.when(
        data: (recipes) {
          final mine = recipes.where((r) => r.authorId == user?.uid).toList();
          if (mine.isEmpty) {
            return const Center(child: Text('You have no recipes.'));
          }
          return ListView.builder(
            itemCount: mine.length,
            itemBuilder: (ctx, i) => RecipeCard(recipe: mine[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
