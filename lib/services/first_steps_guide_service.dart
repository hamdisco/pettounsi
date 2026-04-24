import 'package:shared_preferences/shared_preferences.dart';

class FirstStepsGuideService {
  FirstStepsGuideService._();
  static final instance = FirstStepsGuideService._();

  static const _keyPrefixPending = 'first_steps_guide_pending_v1_';
  static const _keyPrefixShown = 'first_steps_guide_shown_v1_';

  Future<void> markPendingForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefixPending$uid', true);
  }

  Future<bool> shouldShowForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool('$_keyPrefixPending$uid') ?? false;
    final shown = prefs.getBool('$_keyPrefixShown$uid') ?? false;
    return pending && !shown;
  }

  Future<void> markShownForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefixShown$uid', true);
    await prefs.remove('$_keyPrefixPending$uid');
  }
}
