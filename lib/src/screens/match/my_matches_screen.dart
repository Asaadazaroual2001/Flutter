import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/match_providers.dart';
import '../../widgets/match_card.dart';
import 'match_detail_screen.dart';

class MyMatchesScreen extends ConsumerWidget {
  static const routeName = '/my-matches';
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My matches')),
      body: user == null
          ? const Center(child: Text("Login first"))
          : ref.watch(matchesStreamProvider).when(
                data: (matches) {
                  final my =
                      matches.where((m) => m.organizerId == user.uid).toList();
                  if (my.isEmpty)
                    return const Center(
                        child: Text("You didn't create matches yet."));

                  return ListView.builder(
                    itemCount: my.length,
                    itemBuilder: (_, i) => MatchCard(
                      match: my[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        MatchDetailScreen.routeName,
                        arguments: MatchDetailScreenArgs(matchId: my[i].id),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
    );
  }
}
