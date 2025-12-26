import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/match_providers.dart';
import '../../widgets/match_card.dart';
import '../match/create_match_screen.dart';
import '../match/match_detail_screen.dart';
import '../match/my_matches_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MatchUp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(
              context,
              CreateMatchScreen.routeName,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(
              context,
              ProfileScreen.routeName,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Image.asset('assets/logo.jpeg', width: 40, height: 40),
                    const SizedBox(width: 12),
                    const Text(
                      'MatchUp',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('Matches'),
              onTap: () =>
                  Navigator.popAndPushNamed(context, HomeScreen.routeName),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create match'),
              onTap: () => Navigator.popAndPushNamed(
                  context, CreateMatchScreen.routeName),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('My matches'),
              onTap: () =>
                  Navigator.popAndPushNamed(context, MyMatchesScreen.routeName),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () =>
                  Navigator.popAndPushNamed(context, SettingsScreen.routeName),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async => auth.signOut(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by city / area / stadium...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ref.watch(matchesStreamProvider).when(
                  data: (matches) {
                    final q = _searchCtrl.text.trim().toLowerCase();
                    final filtered = matches.where((m) {
                      if (m.status != 'OPEN') return false; // غير المفتوحين
                      if (q.isEmpty) return true;
                      final hay =
                          "${m.city} ${m.area} ${m.stadiumName}".toLowerCase();
                      return hay.contains(q);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text("No open matches yet. Create one!"),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final match = filtered[i];
                        return MatchCard(
                          match: match,
                          onTap: () => Navigator.pushNamed(
                            context,
                            MatchDetailScreen.routeName,
                            arguments: MatchDetailScreenArgs(matchId: match.id),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                ),
          ),
        ],
      ),
    );
  }
}
