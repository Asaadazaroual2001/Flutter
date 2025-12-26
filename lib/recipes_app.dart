import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/admin/seed_data_screen.dart';

import 'src/providers/theme_providers.dart';
import 'src/providers/auth_providers.dart';

import 'src/screens/splash/splash_screen.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/home/home_screen.dart';
import 'src/screens/profile/profile_screen.dart';
import 'src/screens/settings/settings_screen.dart';

// NEW screens
import 'src/screens/match/create_match_screen.dart';
import 'src/screens/match/match_detail_screen.dart';
import 'src/screens/match/my_matches_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'MatchUp',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case SeedDataScreen.routeName:
            return MaterialPageRoute(builder: (_) => const SeedDataScreen());

          case SplashScreen.routeName:
            return MaterialPageRoute(builder: (_) => const SplashScreen());

          case LoginScreen.routeName:
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case HomeScreen.routeName:
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case CreateMatchScreen.routeName:
            return MaterialPageRoute(builder: (_) => const CreateMatchScreen());

          case MatchDetailScreen.routeName:
            final args = settings.arguments as MatchDetailScreenArgs;
            return MaterialPageRoute(
              builder: (_) => MatchDetailScreen(args: args),
            );

          case MyMatchesScreen.routeName:
            return MaterialPageRoute(builder: (_) => const MyMatchesScreen());

          case ProfileScreen.routeName:
            return MaterialPageRoute(builder: (_) => const ProfileScreen());

          case SettingsScreen.routeName:
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
        }
        return null;
      },
      home: authState.when(
        data: (user) => user == null ? const LoginScreen() : const HomeScreen(),
        loading: () => const SplashScreen(),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
