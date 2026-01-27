import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/analytics_service.dart';

class ItemQrScreen extends StatelessWidget {
  final String listId;
  final String itemId;
  final String itemName;
  final int quantity;

  const ItemQrScreen({
    super.key,
    required this.listId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    AnalyticsService.instance.logViewQr();
    final qrValue = 'SSS|$listId|$itemId';

    return Scaffold(
      appBar: AppBar(title: Text('QR: $itemName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$itemName (x$quantity)',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              QrImageView(data: qrValue, version: QrVersions.auto, size: 280),
              const SizedBox(height: 12),
              const Text(
                'Scan this code to mark the item as bought.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
