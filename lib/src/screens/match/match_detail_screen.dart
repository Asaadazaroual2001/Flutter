import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/match_providers.dart';
import '../../utils/firestore_paths.dart';

extension FirstWhereOrNullX<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

class MatchDetailScreenArgs {
  final String matchId;
  const MatchDetailScreenArgs({required this.matchId});
}

class MatchDetailScreen extends ConsumerStatefulWidget {
  static const routeName = '/match-detail';

  final MatchDetailScreenArgs args;
  const MatchDetailScreen({super.key, required this.args});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<String?> _pickPosition(BuildContext context) async {
    const options = ['Any', 'GK', 'DF', 'MF', 'FW'];
    return showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose position'),
        children: options
            .map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, p),
                  child: Text(p),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _showPlayerInfo(BuildContext context, String uid) async {
    final doc =
        await FirebaseFirestore.instance.doc(FirestorePaths.user(uid)).get();

    final data = doc.data() ?? {};
    final name = (data['displayName'] as String?) ?? '—';
    final age = data['age']?.toString() ?? '—';
    final city = (data['city'] as String?) ?? '—';
    final phone = (data['phone'] as String?) ?? '—';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Player info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: $name"),
            Text("Age: $age"),
            Text("City: $city"),
            Text("Phone: $phone"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final matchId = widget.args.matchId;

    final matchAsync = ref.watch(matchByIdProvider(matchId));
    final partsAsync = ref.watch(participantsProvider(matchId));
    final msgsAsync = ref.watch(messagesProvider(matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Match details')),
      body: matchAsync.when(
        data: (match) {
          if (match == null)
            return const Center(child: Text("Match not found"));

          final isOrganizer = user != null && match.organizerId == user.uid;

          return partsAsync.when(
            data: (parts) {
              final uid = user?.uid;

              // participant ديالك (ولا null)
              final myPart = (uid == null)
                  ? null
                  : parts.firstWhereOrNull((p) => p.playerId == uid);

              final joined = myPart != null;
              final myStatus = myPart?.status; // ممكن null

              // kicked: غير إلا كنت participant و status == KICKED (وماشي organizer)
              final isKicked = !isOrganizer && (myStatus == 'KICKED');

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // HEADER INFO
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.stadiumName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text("${match.city} • ${match.area}"),
                          const SizedBox(height: 8),
                          Text(
                              "Players: ${match.acceptedCount}/${match.totalPlayersNeeded}"),
                          const SizedBox(height: 6),
                          Text("Status: ${match.status}"),
                          const SizedBox(height: 10),
                          const Text("Positions needed",
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: match.positionsNeeded
                                .map((p) => Chip(label: Text(p)))
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                          if (myStatus != null) ...[
                            const SizedBox(height: 10),
                            Text("Your status: $myStatus"),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // JOIN / LEAVE
                    if (user == null)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Login to join this match."),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: (match.status != 'OPEN' ||
                                      joined ||
                                      isKicked)
                                  ? null
                                  : () async {
                                      final pos = await _pickPosition(context);
                                      if (pos == null) return;
                                      final service =
                                          ref.read(matchServiceProvider);
                                      await service.joinMatch(
                                        matchId: matchId,
                                        playerId: user.uid,
                                        position: pos,
                                      );
                                    },
                              child: const Text('Join'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (!joined)
                                  ? null
                                  : () async {
                                      final service =
                                          ref.read(matchServiceProvider);
                                      await service.leaveMatch(
                                        matchId: matchId,
                                        playerId: user.uid,
                                      );
                                    },
                              child: const Text('Leave'),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 14),

                    // PARTICIPANTS LIST
                    Expanded(
                      child: ListView(
                        children: [
                          const Text("Participants",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          if (parts.isEmpty)
                            const Text("No participants yet.")
                          else
                            ...parts.map((p) {
                              final canManage = isOrganizer &&
                                  p.playerId != match.organizerId;

                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(p.displayName),
                                subtitle: Text("${p.position} • ${p.status}"),
                                trailing: canManage
                                    ? Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            tooltip: 'Info',
                                            icon:
                                                const Icon(Icons.info_outline),
                                            onPressed: () => _showPlayerInfo(
                                                context, p.playerId),
                                          ),
                                          if (p.status == 'PENDING')
                                            IconButton(
                                              tooltip: 'Accept',
                                              icon: const Icon(Icons.check),
                                              onPressed: () async {
                                                final service = ref
                                                    .read(matchServiceProvider);
                                                await service.acceptPlayer(
                                                  matchId: matchId,
                                                  playerId: p.playerId,
                                                );
                                              },
                                            ),
                                          if (p.status == 'PENDING')
                                            IconButton(
                                              tooltip: 'Reject',
                                              icon: const Icon(Icons.close),
                                              onPressed: () async {
                                                final service = ref
                                                    .read(matchServiceProvider);
                                                await service.rejectPlayer(
                                                  matchId: matchId,
                                                  playerId: p.playerId,
                                                );
                                              },
                                            ),
                                          IconButton(
                                            tooltip: 'Kick',
                                            icon: const Icon(Icons.block),
                                            onPressed: () async {
                                              final service = ref
                                                  .read(matchServiceProvider);
                                              await service.kickPlayer(
                                                matchId: matchId,
                                                playerId: p.playerId,
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                    : (p.playerId == user?.uid
                                        ? const Text("You")
                                        : null),
                              );
                            }),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // CHAT TITLE
                          const Text("Chat",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),

                          // CHAT MESSAGES
                          msgsAsync.when(
                            data: (msgs) {
                              if (msgs.isEmpty) {
                                return const Text("No messages yet.");
                              }
                              return Column(
                                children: msgs.map((m) {
                                  final isMe =
                                      user != null && m.senderId == user.uid;
                                  final roleLabel = m.senderRole == 'ORGANIZER'
                                      ? 'Organizer'
                                      : 'Player';

                                  return Align(
                                    alignment: isMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.all(10),
                                      constraints:
                                          const BoxConstraints(maxWidth: 900),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: Colors.white24),
                                      ),
                                      child: Text(
                                        "${m.senderName} ($roleLabel): ${m.text}",
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Text("Chat error: $e"),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // CHAT INPUT
                    if (user == null)
                      const SizedBox.shrink()
                    else if (isKicked)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("You were kicked. Chat is disabled."),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Write a message...',
                              ),
                              onSubmitted: (_) async {
                                final service = ref.read(matchServiceProvider);
                                await service.sendMessage(
                                  matchId: matchId,
                                  senderId: user.uid,
                                  text: _msgCtrl.text,
                                );
                                _msgCtrl.clear();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              final service = ref.read(matchServiceProvider);
                              await service.sendMessage(
                                matchId: matchId,
                                senderId: user.uid,
                                text: _msgCtrl.text,
                              );
                              _msgCtrl.clear();
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
