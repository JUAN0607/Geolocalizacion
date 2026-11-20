import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('No se pudo leer la zona horaria, se usa Bogotá: $e');
      tz.setLocalLocation(tz.getLocation('America/Bogota'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
  }

  static tz.TZDateTime nextInstanceOf(tz.TZDateTime now, int hour, int minute) {
    var scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> scheduleDailySummary({
    required int hour,
    required int minute,
    required double totalMeters,
  }) async {
    final scheduled = nextInstanceOf(tz.TZDateTime.now(tz.local), hour, minute);

    final vibration = Int64List.fromList([0, 400, 200, 400]);

    final androidDetails = AndroidNotificationDetails(
      'walk_summary_channel',
      'Resumen Diario de Caminata',
      channelDescription: 'Notificaciones diarias de distancia recorrida',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: vibration,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    var exact = await android?.canScheduleExactNotifications() ?? true;
    if (!exact) {
      await android?.requestExactAlarmsPermission();
      exact = await android?.canScheduleExactNotifications() ?? false;
    }

    await _plugin.zonedSchedule(
      0,
      'Resumen Diario de Actividad',
      'Hoy has caminado aprox. ${totalMeters.toStringAsFixed(1)} metros.',
      scheduled,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
