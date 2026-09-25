import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class TaskNotificationService {
  static final TaskNotificationService instance = TaskNotificationService._();

  TaskNotificationService._();

  static const String enabledKey = 'lumi_notifications_enabled';
  static const String timeKey = 'lumi_notification_time';
  static const String _tasksCacheKey = 'lumi_notification_tasks_cache';
  static const String _payload = 'lumi_daily_task_reminder';
  static const String _taskChannelId = 'lumi_tasks_v1';
  static const String _adminChannelId = 'lumi_admin_v1';
  static const int _dailyReminderId = 0x4C554D49;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initializationFuture;

  Future<void> initialize() async {
    debugPrint('[LUMI notifications] initialize() comienza');
    if (_initialized) return;
    if (_initializationFuture != null) return _initializationFuture!;

    _initializationFuture = _initialize();
    return _initializationFuture!;
  }

  Future<void> _initialize() async {
    try {
      tz_data.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      debugPrint(
        '[LUMI notifications] timezone configurado: ${localTimezone.identifier}',
      );

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(settings);

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _taskChannelId,
          'Tareas y Recordatorios',
          description: 'Recordatorios locales de tareas pendientes de Lumi',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('lumi_notification'),
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _adminChannelId,
          'Alertas del Sistema',
          description: 'Alertas administrativas y cambios del sistema de Lumi',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('admin_alert'),
        ),
      );

      _initialized = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(enabledKey, prefs.getBool(enabledKey) ?? true);
      await prefs.setString(timeKey, prefs.getString(timeKey) ?? '18:00');

      if (prefs.getBool(enabledKey) ?? true) {
        final permitted = await requestPermissions();
        await prefs.setBool(enabledKey, permitted);
        if (permitted) {
          await _syncCachedTasks();
        } else {
          await cancelDailyReminder();
        }
      }
      debugPrint('[LUMI notifications] initialize() terminó correctamente');
    } catch (error, stackTrace) {
      debugPrint('TaskNotificationService.initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _initialized = false;
    } finally {
      if (!_initialized) _initializationFuture = null;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      debugPrint('[LUMI notifications] solicitando permisos');
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted = await android?.requestNotificationsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted = (androidGranted ?? iosGranted ?? true) == true;
      debugPrint(
        '[LUMI notifications] permisos resultado: granted=$granted '
        'android=$androidGranted ios=$iosGranted',
      );
      return granted;
    } catch (error, stackTrace) {
      debugPrint('TaskNotificationService.requestPermissions failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    try {
      debugPrint('[LUMI notifications] setEnabled($enabled) comienza');
      await initialize();
      final prefs = await SharedPreferences.getInstance();

      if (!enabled) {
        await prefs.setBool(enabledKey, false);
        await cancelDailyReminder();
        debugPrint('[LUMI notifications] setEnabled(false) aplicado');
        return false;
      }

      final permitted = await requestPermissions();
      await prefs.setBool(enabledKey, permitted);
      if (permitted) {
        await _syncCachedTasks();
      } else {
        await cancelDailyReminder();
      }
      debugPrint(
        '[LUMI notifications] setEnabled($enabled) resultado: $permitted',
      );
      return permitted;
    } catch (error, stackTrace) {
      debugPrint('TaskNotificationService.setEnabled failed: $error');
      debugPrintStack(stackTrace: stackTrace);
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
    debugPrint(
      '[LUMI notifications] cambio de hora solicitado: '
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final value = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    await prefs.setString(timeKey, value);
    await _syncCachedTasks();
    debugPrint('[LUMI notifications] hora guardada y recordatorio sincronizado: $value');
  }

  Future<void> syncTasks(List<dynamic> tasks) async {
    try {
      debugPrint(
        '[LUMI notifications] syncTasks() comienza; tareas recibidas=${tasks.length}',
      );
      await initialize();
      final normalized = tasks
          .whereType<Map>()
          .map(_normalizeTask)
          .whereType<Map<String, dynamic>>()
          .toList();
      debugPrint(
        '[LUMI notifications] tareas válidas y pendientes=${normalized.length}',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tasksCacheKey, jsonEncode(normalized));

      if (!(prefs.getBool(enabledKey) ?? true)) {
        await cancelDailyReminder();
        return;
      }

      await _scheduleDailyReminder(normalized);
    } catch (error, stackTrace) {
      debugPrint('TaskNotificationService.syncTasks failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancelDailyReminder() async {
    try {
      await initialize();
      await _plugin.cancel(_dailyReminderId);
    } catch (error, stackTrace) {
      debugPrint('TaskNotificationService.cancelDailyReminder failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Map<String, dynamic>? _normalizeTask(Map task) {
    final id = task['id']?.toString().trim();
    final rawDate = task['fecha_entrega'] ?? task['fechaEntrega'] ?? task['fecha'];
    if (id == null || id.isEmpty || rawDate == null) return null;

    final title = (task['nombre'] ?? task['titulo'] ?? 'Tarea').toString().trim();
    final completed = task['completada'] == true ||
        task['estado'].toString().toUpperCase() == 'COMPLETADA';
    final date = rawDate.toString().split('T').first.split(' ').first;
    if (completed || !_isValidDate(date)) return null;

    return <String, dynamic>{
      'id': id,
      'title': title.isEmpty ? 'Tarea' : title,
      'date': date,
      'completed': completed,
    };
  }

  Future<void> _scheduleDailyReminder(List<Map<String, dynamic>> tasks) async {
    if (tasks.isEmpty) {
      await cancelDailyReminder();
      return;
    }

    final time = await getReminderTime();
    final timeParts = time.split(':').map(int.parse).toList();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeParts.first,
      timeParts.length > 1 ? timeParts[1] : 0,
    );
    if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
    debugPrint(
      '[LUMI notifications] programando fecha/hora=${scheduled.toIso8601String()} '
      'timezone=${tz.local.name} horaConfigurada=$time',
    );

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _taskChannelId,
        'Tareas y Recordatorios',
        channelDescription: 'Recordatorios locales de tareas pendientes de Lumi',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('lumi_notification'),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await cancelDailyReminder();
    debugPrint('[LUMI notifications] llamando a zonedSchedule()');
    await _plugin.zonedSchedule(
      _dailyReminderId,
      '🔔 LUMI',
      _buildReminderBody(tasks),
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('[LUMI notifications] zonedSchedule() terminó correctamente');
  }

  Future<void> showAdminNotification({
    required String title,
    required String body,
    int id = 0x4C554D42,
  }) async {
    try {
      await initialize();
      final details = NotificationDetails(
        android: const AndroidNotificationDetails(
          _adminChannelId,
          'Alertas del Sistema',
          channelDescription: 'Alertas administrativas y cambios del sistema de Lumi',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('admin_alert'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.show(id, title, body, details, payload: 'lumi_admin_alert');
      debugPrint('[LUMI notifications] notificación administrativa enviada: $title');
    } catch (error, stackTrace) {
      debugPrint('TaskNotificationService.showAdminNotification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _syncCachedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(enabledKey) ?? true)) {
      await cancelDailyReminder();
      return;
    }
    final raw = prefs.getString(_tasksCacheKey);
    if (raw == null || raw.isEmpty) {
      await cancelDailyReminder();
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      await cancelDailyReminder();
      return;
    }
    final tasks = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    await _scheduleDailyReminder(tasks);
  }

  String _buildReminderBody(List<Map<String, dynamic>> tasks) {
    final today = DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    final proximities = tasks.map((task) {
      final parts = (task['date'] as String).split('-').map(int.parse).toList();
      final dueDate = DateTime.utc(parts[0], parts[1], parts[2]);
      return (
        task: task,
        days: dueDate.difference(todayUtc).inDays,
      );
    }).toList();

    if (proximities.length == 1) {
      final item = proximities.first;
      final title = item.task['title'] as String;
      if (item.days < 0) return 'Está vencida: $title.';
      if (item.days == 0) return 'Hoy vence: $title.';
      final dayWord = item.days == 1 ? 'día' : 'días';
      return 'Te quedan ${item.days} $dayWord para completar: $title.';
    }

    final todayCount = proximities.where((item) => item.days == 0).length;
    final tomorrowCount = proximities.where((item) => item.days == 1).length;
    final futureCount = proximities.where((item) => item.days > 1).length;
    final overdueCount = proximities.where((item) => item.days < 0).length;
    final lines = <String>[
      'Tienes ${proximities.length} tareas pendientes.',
    ];
    if (overdueCount > 0) lines.add('$overdueCount están vencidas.');
    if (todayCount > 0) lines.add('$todayCount vence hoy.');
    if (tomorrowCount > 0) lines.add('$tomorrowCount vence mañana.');
    if (futureCount > 0) lines.add('$futureCount tienen más días.');
    lines.add('Entra a LUMI para revisarlas.');
    return lines.join(' ');
  }

  bool _isValidDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime.utc(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }
}
