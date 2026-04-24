import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

class ConnectivityStatusController extends ChangeNotifier
    with WidgetsBindingObserver {
  ConnectivityStatusController._();

  static final ConnectivityStatusController instance =
      ConnectivityStatusController._();

  bool _isOffline = false;
  bool _started = false;
  Timer? _pollTimer;
  DateTime? _lastCheckedAt;

  bool get isOffline => _isOffline;
  DateTime? get lastCheckedAt => _lastCheckedAt;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      refresh(silent: true);
    });
  }

  Future<void> refresh({bool silent = false}) async {
    final nextOffline = !(await _hasInternetConnection());
    _lastCheckedAt = DateTime.now();

    if (_isOffline != nextOffline) {
      _isOffline = nextOffline;
      notifyListeners();
      return;
    }

    if (!silent) {
      notifyListeners();
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh(silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }
}
