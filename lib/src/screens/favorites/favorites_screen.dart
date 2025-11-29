import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../widgets/recipe_card.dart';

class FavoritesScreen extends ConsumerWidget {
  static const routeName = '/favorites';

  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserProvider);
    final recipesAsync = ref.watch(recipesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: appUserAsync.when(
        data: (appUser) {
          if (appUser == null) {
            return const Center(
              child: Text('Login to see your favorites.'),
            );
          }
          return recipesAsync.when(
            data: (recipes) {
              final favs = recipes
                  .where((r) => appUser.favorites.contains(r.id))
                  .toList();
              if (favs.isEmpty) {
                return const Center(
                  child: Text('No favorites yet.'),
                );
              }
              return ListView.builder(
                itemCount: favs.length,
                itemBuilder: (ctx, i) => RecipeCard(recipe: favs[i]),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
