import 'package:flutter/material.dart';
import '../models/match_announcement.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String formatDateTime(DateTime dt) {
  final d = "${_two(dt.day)}/${_two(dt.month)}/${dt.year}";
  final t = "${_two(dt.hour)}:${_two(dt.minute)}";
  return "$d • $t";
}

class MatchCard extends StatelessWidget {
  final MatchAnnouncement match;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final missing = match.missingPlayers;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.stadiumName.isEmpty ? "Stadium" : match.stadiumName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: missing > 0
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.green.withOpacity(0.15),
                    ),
                    child: Text(
                      missing > 0 ? "Missing: $missing" : "FULL",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: missing > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "${match.city} • ${match.area}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatDateTime(match.startAt),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    label: Text(
                        "${match.acceptedCount}/${match.totalPlayersNeeded} players"),
                  ),
                  ...match.positionsNeeded.map((p) => Chip(label: Text(p))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
