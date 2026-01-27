import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/analytics_service.dart';

class ItemQrScreen extends StatefulWidget {
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
  State<ItemQrScreen> createState() => _ItemQrScreenState();
}

class _ItemQrScreenState extends State<ItemQrScreen> {
  late final String _qrValue;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logViewQr();
    _qrValue = 'SSS|${widget.listId}|${widget.itemId}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item QR'),
        actions: [
          IconButton(
            tooltip: 'Copy QR payload',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _qrValue));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR value copied to clipboard.')),
              );
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.itemName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Quantity: ${widget.quantity}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Semantics(
                      label:
                          'QR code for ${widget.itemName}, quantity ${widget.quantity}. Scan to mark as bought.',
                      child: QrImageView(
                        data: _qrValue,
                        version: QrVersions.auto,
                        size: 280,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: cs.onSurface,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scan this code to mark the item as bought.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
