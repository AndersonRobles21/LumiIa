import 'package:shared_preferences/shared_preferences.dart';

class TaskNotificationService {
  static final TaskNotificationService instance = TaskNotificationService._();

  TaskNotificationService._();

  static const String enabledKey = 'lumi_notifications_enabled';
  static const String timeKey = 'lumi_notification_time';

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(enabledKey, prefs.getBool(enabledKey) ?? true);
      await prefs.setString(timeKey, prefs.getString(timeKey) ?? '18:00');
    } catch (_) {}
  }

  Future<bool> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(enabledKey, enabled);
      return enabled;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? true;
  }

  Future<String> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(timeKey) ?? '18:00';
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    final value = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    await prefs.setString(timeKey, value);
  }

  Future<void> syncTasks(List<dynamic> tasks) async {}
}
