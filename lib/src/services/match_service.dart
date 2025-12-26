import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_announcement.dart';
import '../models/match_participation.dart';
import '../models/match_message.dart';
import '../utils/firestore_paths.dart';

class MatchService {
  final FirebaseFirestore _db;

  MatchService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection(FirestorePaths.matches());

  // List matches (upcoming first)
  Stream<List<MatchAnnouncement>> matchesStream() {
    return _matches
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MatchAnnouncement.fromDoc).toList());
  }

  Stream<MatchAnnouncement?> matchByIdStream(String matchId) {
    return _matches.doc(matchId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MatchAnnouncement.fromDoc(doc);
    });
  }

  Future<String> createMatch(MatchAnnouncement match) async {
    final docRef = _matches.doc();
    final now = DateTime.now();

    final data = match
        .copyWith(
          id: docRef.id,
          createdAt: now,
          updatedAt: now,
        )
        .toMap();

    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateMatch(MatchAnnouncement match) async {
    await _matches.doc(match.id).update(
          match.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  Future<void> deleteMatch(String matchId) async {
    await _matches.doc(matchId).delete();
  }

  // Participants
  Stream<List<MatchParticipation>> participantsStream(String matchId) {
    final col = _db.collection(FirestorePaths.participants(matchId));
    return col
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(MatchParticipation.fromDoc).toList());
  }

  /// join -> PENDING (organizer خاصو يقبل)
  Future<void> joinMatch({
    required String matchId,
    required String playerId,
    required String position,
    String message = '',
  }) async {
    final matchRef = _matches.doc(matchId);
    final partRef = _db.doc(FirestorePaths.participant(matchId, playerId));

    // displayName من users
    final uDoc = await _db.doc(FirestorePaths.user(playerId)).get();
    final displayName = (uDoc.data()?['displayName'] as String?) ?? 'Player';

    await _db.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists || matchSnap.data() == null) return;

      final match = MatchAnnouncement.fromDoc(matchSnap);
      if (match.status != 'OPEN') return;

      final partSnap = await tx.get(partRef);
      if (partSnap.exists) return; // منع join مرتين + KICKED ما يرجعش

      tx.set(
        partRef,
        MatchParticipation(
          playerId: playerId,
          displayName: displayName,
          position: position,
          status: 'PENDING',
          message: message,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    });
  }

  /// leave: إلا كان ACCEPTED ينقص acceptedCount
  Future<void> leaveMatch({
    required String matchId,
    required String playerId,
  }) async {
    final matchRef = _matches.doc(matchId);
    final partRef = _db.doc(FirestorePaths.participant(matchId, playerId));

    await _db.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      final partSnap = await tx.get(partRef);

      if (!matchSnap.exists || matchSnap.data() == null) return;
      if (!partSnap.exists || partSnap.data() == null) return;

      final match = MatchAnnouncement.fromDoc(matchSnap);
      final part = MatchParticipation.fromDoc(partSnap);

      tx.delete(partRef);

      if (part.status == 'ACCEPTED') {
        final newAccepted = (match.acceptedCount - 1).clamp(0, 9999);
        tx.update(matchRef, {
          'acceptedCount': newAccepted,
          'status': 'OPEN',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// organizer accept: يزيد acceptedCount و FULL
  Future<void> acceptPlayer({
    required String matchId,
    required String playerId,
  }) async {
    final matchRef = _matches.doc(matchId);
    final partRef = _db.doc(FirestorePaths.participant(matchId, playerId));

    await _db.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      final partSnap = await tx.get(partRef);

      if (!matchSnap.exists || matchSnap.data() == null) return;
      if (!partSnap.exists || partSnap.data() == null) return;

      final match = MatchAnnouncement.fromDoc(matchSnap);
      final part = MatchParticipation.fromDoc(partSnap);

      if (match.acceptedCount >= match.totalPlayersNeeded) {
        tx.update(matchRef, {
          'status': 'FULL',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      if (part.status == 'ACCEPTED') return;

      tx.update(partRef, {
        'status': 'ACCEPTED',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final newAccepted = match.acceptedCount + 1;
      tx.update(matchRef, {
        'acceptedCount': newAccepted,
        'status': (newAccepted >= match.totalPlayersNeeded) ? 'FULL' : 'OPEN',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// organizer reject: إلا كان ACCEPTED ينقص acceptedCount
  Future<void> rejectPlayer({
    required String matchId,
    required String playerId,
  }) async {
    final matchRef = _matches.doc(matchId);
    final partRef = _db.doc(FirestorePaths.participant(matchId, playerId));

    await _db.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      final partSnap = await tx.get(partRef);

      if (!matchSnap.exists || matchSnap.data() == null) return;
      if (!partSnap.exists || partSnap.data() == null) return;

      final match = MatchAnnouncement.fromDoc(matchSnap);
      final part = MatchParticipation.fromDoc(partSnap);

      if (part.status == 'ACCEPTED') {
        final newAccepted = (match.acceptedCount - 1).clamp(0, 9999);
        tx.update(matchRef, {
          'acceptedCount': newAccepted,
          'status': 'OPEN',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(partRef, {
        'status': 'REJECTED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// organizer kick: ما نمسحوش doc، نخليه KICKED باش يتمنع الشات والرجوع
  Future<void> kickPlayer({
    required String matchId,
    required String playerId,
  }) async {
    final matchRef = _matches.doc(matchId);
    final partRef = _db.doc(FirestorePaths.participant(matchId, playerId));

    await _db.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      final partSnap = await tx.get(partRef);

      if (!matchSnap.exists || matchSnap.data() == null) return;
      if (!partSnap.exists || partSnap.data() == null) return;

      final match = MatchAnnouncement.fromDoc(matchSnap);
      final part = MatchParticipation.fromDoc(partSnap);

      if (part.status == 'ACCEPTED') {
        final newAccepted = (match.acceptedCount - 1).clamp(0, 9999);
        tx.update(matchRef, {
          'acceptedCount': newAccepted,
          'status': 'OPEN',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(partRef, {
        'status': 'KICKED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Messages
  Stream<List<MatchMessage>> messagesStream(String matchId) {
    final col = _db.collection(FirestorePaths.messages(matchId));
    return col
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MatchMessage.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final matchRef = _matches.doc(matchId);
    final partRef = _db.doc(FirestorePaths.participant(matchId, senderId));
    final msgRef = _db.collection(FirestorePaths.messages(matchId)).doc();

    final uDoc = await _db.doc(FirestorePaths.user(senderId)).get();
    final senderName = (uDoc.data()?['displayName'] as String?) ?? 'Player';

    await _db.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists || matchSnap.data() == null) return;

      final match = MatchAnnouncement.fromDoc(matchSnap);
      final isOrganizer = match.organizerId == senderId;

      if (!isOrganizer) {
        final partSnap = await tx.get(partRef);
        if (!partSnap.exists || partSnap.data() == null) return;

        final status = (partSnap.data()!['status'] as String?) ?? '';
        if (status == 'KICKED') return;
      }

      tx.set(
        msgRef,
        MatchMessage(
          id: msgRef.id,
          senderId: senderId,
          senderName: senderName,
          senderRole: isOrganizer ? 'ORGANIZER' : 'PLAYER',
          text: clean,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    });
  }
}

// Extension copyWith باش نسهلو create/update
extension MatchCopy on MatchAnnouncement {
  MatchAnnouncement copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? acceptedCount,
    String? status,
  }) {
    return MatchAnnouncement(
      id: id ?? this.id,
      organizerId: organizerId,
      stadiumId: stadiumId,
      stadiumName: stadiumName,
      city: city,
      area: area,
      startAt: startAt,
      durationMin: durationMin,
      totalPlayersNeeded: totalPlayersNeeded,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      positionsNeeded: positionsNeeded,
      notes: notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
