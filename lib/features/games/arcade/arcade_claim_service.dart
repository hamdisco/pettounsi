import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/user_identity_service.dart';

class ArcadeClaimResult {
  const ArcadeClaimResult({
    required this.success,
    required this.message,
    required this.reward,
  });

  final bool success;
  final String message;
  final int reward;
}

class ArcadeClaimService {
  ArcadeClaimService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String todayKey([DateTime? value]) {
    final now = value ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  static int catchTreatReward(int score) {
    if (score >= 420) return 15;
    if (score >= 280) return 12;
    if (score >= 170) return 8;
    if (score >= 80) return 5;
    if (score >= 30) return 2;
    return 0;
  }

  static int petMemoryScore({required int moves, required int seconds}) {
    final raw = 1000 - (moves * 32) - (seconds * 7);
    if (raw < 0) return 0;
    if (raw > 1000) return 1000;
    return raw;
  }

  static int petMemoryReward(int score) {
    if (score >= 820) return 15;
    if (score >= 650) return 12;
    if (score >= 480) return 8;
    if (score >= 300) return 5;
    if (score >= 120) return 2;
    return 0;
  }

  static int bubblePawsReward(int score) {
    if (score >= 360) return 15;
    if (score >= 280) return 12;
    if (score >= 190) return 8;
    if (score >= 100) return 5;
    if (score >= 40) return 2;
    return 0;
  }

  // Kept for compatibility if an older Paw Dash file is still present under lib/.
  static int pawDashReward(int score) => bubblePawsReward(score);

  static int petQuizReward(int correctAnswers) {
    if (correctAnswers >= 5) return 15;
    if (correctAnswers >= 4) return 12;
    if (correctAnswers >= 3) return 8;
    if (correctAnswers >= 2) return 5;
    if (correctAnswers >= 1) return 2;
    return 0;
  }

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
        message: 'Play again to reach the minimum score for points.',
        reward: 0,
      );
    }

    final safeGameId = gameId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    final dayKey = todayKey();
    final claimRef = _db.collection('game_claims').doc('${uid}_${dayKey}_arcade_$safeGameId');
    final identity = await UserIdentityService.instance.getForUid(
      uid,
      authUser: user,
    );
    final displayName = identity.safeName;
    final email = identity.email.trim();
    final title = _trimTitle('$gameTitle · $score score');

    try {
      await _db.runTransaction((tx) async {
        final existing = await tx.get(claimRef);
        if (existing.exists) {
          final status = (existing.data()?['status'] ?? 'pending').toString().toLowerCase();
          if (status == 'approved') {
            throw const _ArcadeClaimException('Points for this game are already approved today.');
          }
          if (status == 'pending') {
            throw const _ArcadeClaimException('Your points for this game are already pending review today.');
          }
          throw const _ArcadeClaimException('This game was already claimed today.');
        }

        tx.set(claimRef, {
          'uid': uid,
          'dayKey': dayKey,
          'missionId': 'arcade_$safeGameId',
          'missionTitle': title,
          'missionReward': reward,
          'status': 'pending',
          'source': 'arcade_game_v1',
          'gameId': safeGameId,
          'score': score,
          'durationSeconds': durationSeconds,
          'gameResult': _trimResult(resultLabel),
          if (displayName.isNotEmpty) 'userDisplayName': displayName,
          if (email.isNotEmpty) 'userEmail': email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return ArcadeClaimResult(
        success: true,
        message: '+$reward pts sent for review.',
        reward: reward,
      );
    } on _ArcadeClaimException catch (e) {
      return ArcadeClaimResult(success: false, message: e.message, reward: reward);
    } catch (_) {
      return ArcadeClaimResult(
        success: false,
        message: 'Could not submit points. Please try again.',
        reward: reward,
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
