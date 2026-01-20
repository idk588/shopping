import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'shopping_reminders';
  static const String _channelName = 'Shopping Reminders';
  static const String _channelDesc = 'Reminders for shopping lists';

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Create Android notification channel (required Android 8+)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  Future<bool> requestPermissionIfNeeded() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return true;

    // Android 13+ requires runtime permission
    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  Future<void> showTestNow() async {
    await _plugin.show(
      1,
      'Test Notification',
      'This is a local notification from your shopping app.',
      _details(),
    );
  }

  /// Great for demo: notifications appear every minute
  Future<void> startEveryMinuteReminder() async {
    await _plugin.periodicallyShow(
      2,
      'Shopping Reminder',
      'Open your list and scan items to mark them bought.',
      RepeatInterval.everyMinute,
      _details(),
      androidAllowWhileIdle: true,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
