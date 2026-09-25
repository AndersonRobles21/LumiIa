import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundAssets {
  static const String taskComplete = 'sounds/task_complete.mp3';
  static const String achievementUnlocked = 'sounds/achievement_unlocked.mp3';
  static const String streakUp = 'sounds/streak_up.mp3';
  static const String pomodoroDone = 'sounds/pomodoro_done.mp3';
  static const String feynmanSuccess = 'sounds/feynman_success.mp3';
  static const String adminAlert = 'sounds/admin_alert.mp3';
}

enum LumiSound { taskCompleted, pomodoroCompleted, achievement, levelUp }

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();
  static const String _enabledKey = 'lumi_sound_enabled';

  final AudioPlayer _player = AudioPlayer();
  bool isSoundEnabled = true;

  bool get soundEnabled => isSoundEnabled;

  set soundEnabled(bool value) => isSoundEnabled = value;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    isSoundEnabled = preferences.getBool(_enabledKey) ?? true;
  }

  Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    isSoundEnabled = preferences.getBool(_enabledKey) ?? isSoundEnabled;
    return isSoundEnabled;
  }

  Future<bool> setEnabled(bool enabled) async {
    isSoundEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);

    if (!enabled) {
      try {
        await _player.stop();
      } catch (error, stackTrace) {
        debugPrint('[LUMI sound] setEnabled(false) stop error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return enabled;
  }

  Future<void> playTaskCompleted() async => _play(SoundAssets.taskComplete);

  Future<void> playAchievementUnlocked() async =>
      _play(SoundAssets.achievementUnlocked);

  Future<void> playStreakUp() async => _play(SoundAssets.streakUp);

  Future<void> playPomodoroDone() async => _play(SoundAssets.pomodoroDone);

  Future<void> playFeynmanSuccess() async => _play(SoundAssets.feynmanSuccess);

  Future<void> playAdminAlert() async => _play(SoundAssets.adminAlert);

  Future<void> play(LumiSound sound) async {
    try {
      final enabled = await isEnabled();
      if (!enabled) return;
      await _player.stop();
      await _player.play(AssetSource(_assetFor(sound)));
    } catch (error, stackTrace) {
      debugPrint('[LUMI sound] Error reproduciendo el efecto: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _play(String assetPath) async {
    try {
      if (!isSoundEnabled) return;
      final preferences = await SharedPreferences.getInstance();
      final enabled = preferences.getBool(_enabledKey) ?? isSoundEnabled;
      if (!enabled) return;

      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (error, stackTrace) {
      debugPrint('[LUMI sound] Error reproduciendo $assetPath: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _assetFor(LumiSound sound) {
    switch (sound) {
      case LumiSound.taskCompleted:
        return SoundAssets.taskComplete;
      case LumiSound.pomodoroCompleted:
        return SoundAssets.pomodoroDone;
      case LumiSound.achievement:
        return SoundAssets.achievementUnlocked;
      case LumiSound.levelUp:
        return SoundAssets.streakUp;
    }
  }
}

