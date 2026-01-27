import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

import '../services/notification_service.dart';
import '../services/analytics_service.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final Battery _battery = Battery();
  int? _level;
  BatteryState? _state;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logOpenDeviceStatus();
    _refresh();
    _battery.onBatteryStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
    });
  }

  Future<void> _refresh() async {
    final lvl = await _battery.batteryLevel;
    final st = await _battery.batteryState;
    if (!mounted) return;
    setState(() {
      _level = lvl;
      _state = st;
    });
  }

  Future<bool> _ensurePermissionWithUi() async {
    final messenger = ScaffoldMessenger.of(context);

    final ok = await NotificationService.instance.requestPermissionIfNeeded();
    if (!mounted) return false;

    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification permission not granted.')),
      );
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final level = _level;
    final levelText = level == null ? 'Loading…' : '$level%';
    final stateText = _state?.toString().split('.').last ?? 'Loading…';
    final progress = level == null ? null : (level.clamp(0, 100) / 100.0);

    IconData stateIcon;
    switch (_state) {
      case BatteryState.charging:
        stateIcon = Icons.bolt;
        break;
      case BatteryState.full:
        stateIcon = Icons.battery_full;
        break;
      case BatteryState.discharging:
        stateIcon = Icons.battery_5_bar;
        break;
      default:
        stateIcon = Icons.battery_unknown;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Status'),
        actions: [
          IconButton(
            tooltip: 'Refresh battery info',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.battery_std, color: cs.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Battery',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(levelText),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (progress == null)
                      const LinearProgressIndicator()
                    else
                      LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(stateIcon, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(child: Text('State: $stateText')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        final ok = await _ensurePermissionWithUi();
                        if (!mounted) return;
                        if (!ok) return;

                        await NotificationService.instance.showTestNow();
                        if (!mounted) return;

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Send test notification now'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        final ok = await _ensurePermissionWithUi();
                        if (!mounted) return;
                        if (!ok) return;

                        await NotificationService.instance
                            .startEveryMinuteReminder();
                        if (!mounted) return;

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Every-minute reminder started.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('Start every-minute reminder (demo)'),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        await NotificationService.instance.cancelAll();
                        if (!mounted) return;

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('All notifications cancelled.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel all notifications'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
