import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/user_identity_service.dart';

class ArcadeClaimResult {
  const ArcadeClaimResult({
    required this.success,
    required this.message,
    required this.reward,
    this.collectedToday = false,
  });

  final bool success;
  final String message;
  final int reward;
  final bool collectedToday;
}

class ArcadeClaimService {
  ArcadeClaimService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int dailyGameReward = 1;

  static String todayKey([DateTime? value]) {
    final now = value ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  static String safeGameId(String gameId) {
    return gameId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  }

  static String claimIdForGame({
    required String uid,
    required String gameId,
    String? dayKey,
  }) {
    final safeId = safeGameId(gameId);
    return '${uid}_${dayKey ?? todayKey()}_arcade_$safeId';
  }

  static Future<bool> hasCollectedToday(String gameId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;
    final claim = await _db
        .collection('game_claims')
        .doc(claimIdForGame(uid: uid, gameId: gameId))
        .get();
    return claim.exists;
  }

  static int catchTreatReward(int score) => score > 0 ? dailyGameReward : 0;

  static int petMemoryScore({required int moves, required int seconds}) {
    final raw = 1000 - (moves * 32) - (seconds * 7);
    if (raw < 0) return 0;
    if (raw > 1000) return 1000;
    return raw;
  }

  static int petMemoryReward(int score) => score > 0 ? dailyGameReward : 0;

  static int bubblePawsReward(int score) => score > 0 ? dailyGameReward : 0;

  // Kept for compatibility if an older Paw Dash file is still present under lib/.
  static int pawDashReward(int score) => bubblePawsReward(score);

  static int petQuizReward(int correctAnswers) => correctAnswers > 0 ? dailyGameReward : 0;

  static Future<ArcadeClaimResult> submitArcadeClaim({
    required String gameId,
    required String gameTitle,
    required int score,
    required int reward,
    required int durationSeconds,
    required String resultLabel,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) {
      return const ArcadeClaimResult(
        success: false,
        message: 'Sign in to collect points.',
        reward: 0,
      );
    }

    if (reward <= 0) {
      return const ArcadeClaimResult(
        success: false,
        message: 'Finish the round with a score to collect today\'s point.',
        reward: 0,
      );
    }

    final safeId = safeGameId(gameId);
    final dayKey = todayKey();
    final claimRef = _db.collection('game_claims').doc(
          claimIdForGame(uid: uid, gameId: safeId, dayKey: dayKey),
        );
    final identity = await UserIdentityService.instance.getForUid(
      uid,
      authUser: user,
    );
    final displayName = identity.safeName;
    final email = identity.email.trim();
    final title = _trimTitle('$gameTitle · one play today');

    try {
      await _db.runTransaction((tx) async {
        final existing = await tx.get(claimRef);
        if (existing.exists) {
          throw const _ArcadeClaimException(
            'This game already counted today. Come back tomorrow.',
          );
        }

        tx.set(claimRef, {
          'uid': uid,
          'dayKey': dayKey,
          'missionId': 'arcade_$safeId',
          'missionTitle': title,
          'missionReward': dailyGameReward,
          'status': 'approved',
          'source': 'arcade_game_v3_auto',
          'gameId': safeId,
          'score': score,
          'durationSeconds': durationSeconds,
          'gameResult': _trimResult(resultLabel),
          if (displayName.isNotEmpty) 'userDisplayName': displayName,
          if (email.isNotEmpty) 'userEmail': email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return const ArcadeClaimResult(
        success: true,
        message: '+1 point added automatically.',
        reward: dailyGameReward,
        collectedToday: true,
      );
    } on _ArcadeClaimException catch (e) {
      return ArcadeClaimResult(
        success: false,
        message: e.message,
        reward: dailyGameReward,
        collectedToday: true,
      );
    } catch (_) {
      return const ArcadeClaimResult(
        success: false,
        message: 'Could not add the point. Please try again.',
        reward: dailyGameReward,
      );
    }
  }

  static String _trimTitle(String value) {
    final clean = value.trim();
    if (clean.length <= 110) return clean;
    return '${clean.substring(0, 107)}...';
  }

  static String _trimResult(String value) {
    final clean = value.trim();
    if (clean.length <= 70) return clean;
    return '${clean.substring(0, 67)}...';
  }
}

class _ArcadeClaimException implements Exception {
  const _ArcadeClaimException(this.message);
  final String message;
}
