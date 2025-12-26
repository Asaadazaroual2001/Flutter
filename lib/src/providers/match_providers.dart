import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_announcement.dart';
import '../models/match_participation.dart';
import '../services/match_service.dart';
import '../models/match_message.dart';

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService();
});

final matchesStreamProvider = StreamProvider<List<MatchAnnouncement>>((ref) {
  final service = ref.watch(matchServiceProvider);
  return service.matchesStream();
});

final matchByIdProvider =
    StreamProvider.family<MatchAnnouncement?, String>((ref, matchId) {
  final service = ref.watch(matchServiceProvider);
  return service.matchByIdStream(matchId);
});

final participantsProvider =
    StreamProvider.family<List<MatchParticipation>, String>((ref, matchId) {
  final service = ref.watch(matchServiceProvider);
  return service.participantsStream(matchId);
});

final messagesProvider =
    StreamProvider.family<List<MatchMessage>, String>((ref, matchId) {
  return ref.watch(matchServiceProvider).messagesStream(matchId);
});
