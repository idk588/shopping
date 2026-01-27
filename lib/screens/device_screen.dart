import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/notification_service.dart';

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
    _refresh();
    _battery.onBatteryStateChanged.listen((s) {
      setState(() => _state = s);
    });
  }

  Future<void> _refresh() async {
    final lvl = await _battery.batteryLevel;
    final st = await _battery.batteryState;
    setState(() {
      _level = lvl;
      _state = st;
    });
  }

  Future<void> _ensurePermission() async {
    final ok = await NotificationService.instance.requestPermissionIfNeeded();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission not granted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelText = _level == null ? 'Loading…' : '$_level%';
    final stateText = _state?.toString().split('.').last ?? 'Loading…';

    return Scaffold(
      appBar: AppBar(title: const Text('Device Status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: const Text('Battery Level'),
                subtitle: Text(levelText),
                trailing: IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Battery State'),
                subtitle: Text(stateText),
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
                    ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        await _ensurePermission();
                        if (!mounted) return;

                        await NotificationService.instance.showTestNow();
                        if (!mounted) return;

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent.'),
                          ),
                        );
                      },
                      child: const Text('Send test notification now'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        await _ensurePermission();
                        if (!mounted) return;

                        await NotificationService.instance
                            .startEveryMinuteReminder();
                        if (!mounted) return;

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Every-minute reminder started.'),
                          ),
                        );
                      },
                      child: const Text('Start every-minute reminder (demo)'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        await _ensurePermission();
                        if (!mounted) return;

                        await NotificationService.instance.cancelAll();
                        if (!mounted) return;

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('All notifications cancelled.'),
                          ),
                        );
                      },
                      child: const Text('Cancel all notifications'),
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
