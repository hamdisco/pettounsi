import 'package:flutter/services.dart';

class InAppSoundService {
  InAppSoundService._();
  static final InAppSoundService instance = InAppSoundService._();

  DateTime? _lastNotificationAt;
  DateTime? _lastMessageAt;

  static const Duration _cooldown = Duration(milliseconds: 650);

  Future<void> playNotificationSound() async {
    final now = DateTime.now();
    if (_lastNotificationAt != null && now.difference(_lastNotificationAt!) < _cooldown) {
      return;
    }
    _lastNotificationAt = now;
    await _playAlert();
  }

  Future<void> playMessageSound() async {
    final now = DateTime.now();
    if (_lastMessageAt != null && now.difference(_lastMessageAt!) < _cooldown) {
      return;
    }
    _lastMessageAt = now;
    await _playAlert();
  }

  Future<void> _playAlert() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Best-effort only.
    }
  }
}
