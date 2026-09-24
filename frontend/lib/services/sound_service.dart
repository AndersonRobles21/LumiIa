import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LumiSound { taskCompleted, pomodoroCompleted, achievement, levelUp }

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();
  static const _enabledKey = 'lumi_sounds_enabled';

  final AudioPlayer _player = AudioPlayer();

  Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? true;
  }

  Future<bool> setEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
    if (!enabled) {
      try {
        await _player.stop();
      } catch (_) {}
    }
    return enabled;
  }

  Future<void> play(LumiSound sound) async {
    try {
      if (!await isEnabled()) return;
      await _player.stop();
      await _player.play(AssetSource(_assetFor(sound)));
    } catch (_) {
      // El audio es opcional: un fallo de reproducción nunca interrumpe LUMI.
    }
  }

  String _assetFor(LumiSound sound) {
    switch (sound) {
      case LumiSound.taskCompleted:
        return 'logo/sounds/task_completed.wav';
      case LumiSound.pomodoroCompleted:
        return 'logo/sounds/pomodoro_completed.wav';
      case LumiSound.achievement:
        return 'logo/sounds/achievement.wav';
      case LumiSound.levelUp:
        return 'logo/sounds/achievement.wav';
    }
  }
}
