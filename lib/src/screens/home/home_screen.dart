import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../../providers/auth_providers.dart';
import '../../providers/filter_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../widgets/recipe_card.dart';
import '../favorites/favorites_screen.dart';
import '../my_recipes/my_recipes_screen.dart';
import '../profile/profile_screen.dart';
import '../recipe/edit_recipe_screen.dart';
import '../recipe/recipe_detail_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  late final PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 0;
  int _carouselItemCount = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(searchQueryProvider);
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _setupCarouselTimer(int itemCount) {
    _carouselTimer?.cancel();

    if (itemCount <= 1) return;

    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || itemCount <= 1) return;

      setState(() {
        _currentPage = (_currentPage + 1) % itemCount;
      });

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(filteredRecipesProvider);

    // WATCH SEARCH + FILTERS
    final searchQuery = ref.watch(searchQueryProvider);
    final categoryFilter = ref.watch(categoryFilterProvider);
    final difficultyFilter = ref.watch(difficultyFilterProvider);
    final maxPrepTimeFilter = ref.watch(maxPrepTimeFilterProvider);

    final hasActiveFilters =
        searchQuery.trim().isNotEmpty ||
        categoryFilter != null ||
        difficultyFilter != null ||
        maxPrepTimeFilter != null;

    // BEST RATED (TOP 5 by avgRating)
    // 👉 Only build carousel when search panel is CLOSED AND no filters are active
    List<Recipe> featuredRecipes = [];
    if (!_showSearch && !hasActiveFilters) {
      featuredRecipes = [...recipes];
      featuredRecipes.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      if (featuredRecipes.length > 5) {
        featuredRecipes = featuredRecipes.sublist(0, 5);
      }
    }

    // Setup / update carousel timer when item count changes
    if (featuredRecipes.length != _carouselItemCount) {
      _carouselItemCount = featuredRecipes.length;
      _currentPage = 0;
      _setupCarouselTimer(_carouselItemCount);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () =>
                Navigator.of(context).pushNamed(ProfileScreen.routeName),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo.jpeg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Recipes App',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.popAndPushNamed(context, '/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('My Recipes'),
              onTap: () {
                Navigator.popAndPushNamed(
                  context,
                  MyRecipesScreen.routeName,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.popAndPushNamed(
                  context,
                  FavoritesScreen.routeName,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.popAndPushNamed(
                  context,
                  SettingsScreen.routeName,
                );
              },
            ),
            const Divider(),
            Consumer(
              builder: (context, ref, _) {
                final auth = ref.read(authServiceProvider);
                return ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await auth.signOut();
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: ref.watch(recipesStreamProvider).when(
            data: (_) {
              return CustomScrollView(
                slivers: [
                  // SEARCH + FILTERS
                  SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _showSearch
                          ? Column(
                              key: const ValueKey('search_filters'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by title or ingredients',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          ref
                                              .read(searchQueryProvider
                                                  .notifier)
                                              .state = '';
                                        },
                                      ),
                                    ),
                                    onChanged: (value) => ref
                                        .read(searchQueryProvider.notifier)
                                        .state = value,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    children: [
                                      FilterChip(
                                        label: const Text('Breakfast'),
                                        selected:
                                            ref.watch(categoryFilterProvider) ==
                                                'Breakfast',
                                        onSelected: (selected) {
                                          ref
                                              .read(categoryFilterProvider
                                                  .notifier)
                                              .state = selected
                                                  ? 'Breakfast'
                                                  : null;
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Lunch'),
                                        selected:
                                            ref.watch(categoryFilterProvider) ==
                                                'Lunch',
                                        onSelected: (selected) {
                                          ref
                                              .read(categoryFilterProvider
                                                  .notifier)
                                              .state =
                                                  selected ? 'Lunch' : null;
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Dinner'),
                                        selected:
                                            ref.watch(categoryFilterProvider) ==
                                                'Dinner',
                                        onSelected: (selected) {
                                          ref
                                              .read(categoryFilterProvider
                                                  .notifier)
                                              .state =
                                                  selected ? 'Dinner' : null;
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Dessert'),
                                        selected:
                                            ref.watch(categoryFilterProvider) ==
                                                'Dessert',
                                        onSelected: (selected) {
                                          ref
                                              .read(categoryFilterProvider
                                                  .notifier)
                                              .state =
                                                  selected ? 'Dessert' : null;
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Easy'),
                                        selected: ref.watch(
                                                difficultyFilterProvider) ==
                                            'Easy',
                                        onSelected: (selected) {
                                          ref
                                              .read(difficultyFilterProvider
                                                  .notifier)
                                              .state =
                                                  selected ? 'Easy' : null;
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Medium'),
                                        selected: ref.watch(
                                                difficultyFilterProvider) ==
                                            'Medium',
                                        onSelected: (selected) {
                                          ref
                                              .read(difficultyFilterProvider
                                                  .notifier)
                                              .state =
                                                  selected ? 'Medium' : null;
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Hard'),
                                        selected: ref.watch(
                                                difficultyFilterProvider) ==
                                            'Hard',
                                        onSelected: (selected) {
                                          ref
                                              .read(difficultyFilterProvider
                                                  .notifier)
                                              .state =
                                                  selected ? 'Hard' : null;
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('≤ 30 min'),
                                        selected: ref.watch(
                                                maxPrepTimeFilterProvider) ==
                                            30,
                                        onSelected: (selected) {
                                          ref
                                              .read(maxPrepTimeFilterProvider
                                                  .notifier)
                                              .state =
                                                  selected ? 30 : null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('no_search'),
                            ),
                    ),
                  ),

                  // CAROUSEL – only when search is CLOSED and no filters
                  if (!_showSearch &&
                      !hasActiveFilters &&
                      featuredRecipes.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.width * 0.55,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: featuredRecipes.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemBuilder: (ctx, i) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _FeaturedRecipeCard(
                                      recipe: featuredRecipes[i],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                featuredRecipes.length,
                                (i) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _currentPage
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // RECIPES GRID
                  if (_showSearch && !hasActiveFilters)
                    // 🔥 Search is open & no filters/query → EMPTY SPACE
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: SizedBox.shrink(),
                    )
                  else if (recipes.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No recipes yet.'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final recipe = recipes[i];
                            return RecipeCard(recipe: recipe);
                          },
                          childCount: recipes.length,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(
            EditRecipeScreen.routeName,
            arguments: const EditRecipeScreenArgs(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Compact card used ONLY in the carousel.
class _FeaturedRecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _FeaturedRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          RecipeDetailScreen.routeName,
          arguments: RecipeDetailScreenArgs(
            recipeId: recipe.id,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (recipe.imageUrl.isNotEmpty)
              Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              )
            else
              Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 40),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.category} • ${recipe.difficulty} • ${recipe.prepTimeMin} min',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
