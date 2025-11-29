import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/providers/theme_providers.dart';
import 'src/providers/auth_providers.dart';
import 'src/screens/splash/splash_screen.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/home/home_screen.dart';
import 'src/screens/recipe/recipe_detail_screen.dart';
import 'src/screens/recipe/edit_recipe_screen.dart';
import 'src/screens/my_recipes/my_recipes_screen.dart';
import 'src/screens/favorites/favorites_screen.dart';
import 'src/screens/profile/profile_screen.dart';
import 'src/screens/settings/settings_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'Flutter Recipes App',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case SplashScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          case LoginScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case HomeScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
          case EditRecipeScreen.routeName:
            final args = settings.arguments as EditRecipeScreenArgs?;
            return MaterialPageRoute(
              builder: (_) => EditRecipeScreen(
                args: args ?? const EditRecipeScreenArgs(),
              ),
            );
          case RecipeDetailScreen.routeName:
            final args = settings.arguments as RecipeDetailScreenArgs;
            return MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(args: args),
            );
          case MyRecipesScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const MyRecipesScreen(),
            );
          case FavoritesScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const FavoritesScreen(),
            );
          case ProfileScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            );
          case SettingsScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            );
        }
        return null;
      },
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
        },
        loading: () => const SplashScreen(),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
