import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logCreateList() => _analytics.logEvent(name: 'create_list');
  Future<void> logAddItem() => _analytics.logEvent(name: 'add_item');
  Future<void> logViewQr() => _analytics.logEvent(name: 'view_qr');
  Future<void> logScanSuccess() => _analytics.logEvent(name: 'scan_success');
  Future<void> logScanInvalid() => _analytics.logEvent(name: 'scan_invalid');
  Future<void> logMarkBought() => _analytics.logEvent(name: 'mark_bought');
  Future<void> logOpenDeviceStatus() =>
      _analytics.logEvent(name: 'open_device_status');
}
