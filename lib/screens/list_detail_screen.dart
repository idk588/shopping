import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../storage/keys.dart';
import '../services/analytics_service.dart';

import 'scan_screen.dart';
import 'device_screen.dart';
import 'item_qr_screen.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId;
  const ListDetailScreen({super.key, required this.listId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  Box get _box => Hive.box(HiveKeys.listsBox);

  ShoppingListModel _load() {
    final raw = _box.get(widget.listId);
    return ShoppingListModel.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> _save(ShoppingListModel list) async {
    await _box.put(list.id, list.toMap());
  }

  Future<void> _addItem(ShoppingListModel list) async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item name (e.g., Milk)',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity (e.g., 2)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text.trim()) ?? 1;
              Navigator.pop(context, {'name': name, 'qty': qty < 1 ? 1 : qty});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == null) return;

    final name = (result['name'] as String?)?.trim() ?? '';
    final qty = (result['qty'] as int?) ?? 1;

    if (name.isEmpty) return;

    final item = ShoppingItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      quantity: qty < 1 ? 1 : qty,
      bought: false,
    );

    list.items.add(item);
    await _save(list);
    await AnalyticsService.instance.logAddItem();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleBought(ShoppingListModel list, ShoppingItem item) async {
    item.bought = !item.bought;
    await _save(list);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteItem(ShoppingListModel list, ShoppingItem item) async {
    list.items.removeWhere((x) => x.id == item.id);
    await _save(list);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editQuantity(ShoppingListModel list, ShoppingItem item) async {
    final qtyController = TextEditingController(text: item.quantity.toString());

    final qty = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Quantity for "${item.name}"'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(qtyController.text.trim());
              Navigator.pop(
                context,
                (parsed == null || parsed < 1) ? item.quantity : parsed,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (qty == null) return;

    item.quantity = qty;
    await _save(list);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openScannerToMark(ShoppingListModel list) async {
    final messenger = ScaffoldMessenger.of(context);

    final scanned = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanScreen(title: 'Scan item QR to mark bought'),
      ),
    );

    if (!mounted) return;
    if (scanned == null || scanned.isEmpty) return;

    // Expected QR format: SSS|<listId>|<itemId>
    final parts = scanned.split('|');
    if (parts.length != 3 || parts[0] != 'SSS') {
      await AnalyticsService.instance.logScanInvalid();
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid QR code (not from this app).')),
      );
      return;
    }

    final scannedListId = parts[1];
    final scannedItemId = parts[2];

    if (scannedListId != list.id) {
      messenger.showSnackBar(
        const SnackBar(content: Text('This QR belongs to a different list.')),
      );
      return;
    }

    final match = list.items.where((it) => it.id == scannedItemId).toList();
    if (match.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Item not found in this list.')),
      );
      return;
    }

    final item = match.first;

    if (item.bought) {
      messenger.showSnackBar(
        SnackBar(content: Text('"${item.name}" is already marked as bought.')),
      );
      return;
    }

    item.bought = true;
    await AnalyticsService.instance.logScanSuccess();

    await _save(list);
    if (!mounted) return;

    setState(() {});
    messenger.showSnackBar(
      SnackBar(content: Text('Marked "${item.name}" as bought.')),
    );

    final allBought =
        list.items.isNotEmpty && list.items.every((x) => x.bought);
    if (allBought) {
      messenger.showSnackBar(
        const SnackBar(content: Text('List completed. All items bought!')),
      );
    }
  }

  Future<void> _markAllUnbought(ShoppingListModel list) async {
    for (final it in list.items) {
      it.bought = false;
    }
    await _save(list);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteBoughtItems(ShoppingListModel list) async {
    list.items.removeWhere((x) => x.bought);
    await _save(list);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = _load();

    final total = list.items.length;
    final boughtCount = list.items.where((x) => x.bought).length;
    final progress = total == 0 ? 0.0 : boughtCount / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(list.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Device status',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceScreen()),
            ),
            icon: const Icon(Icons.battery_full),
          ),
          IconButton(
            tooltip: 'Scan to mark bought',
            onPressed: () => _openScannerToMark(list),
            icon: const Icon(Icons.qr_code_scanner),
          ),
          PopupMenuButton<String>(
            tooltip: 'List options',
            onSelected: (value) async {
              if (value == 'reset') {
                await _markAllUnbought(list);
              } else if (value == 'deleteBought') {
                await _deleteBoughtItems(list);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'reset',
                child: Text('Reset all to not bought'),
              ),
              PopupMenuItem(
                value: 'deleteBought',
                child: Text('Delete bought items'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add item',
        onPressed: () => _addItem(list),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist, color: cs.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text('$boughtCount / $total'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      total == 0
                          ? 'Add items to start tracking.'
                          : (boughtCount == total
                                ? 'All items bought 🎉'
                                : 'Keep going!'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: total == 0
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.playlist_add, size: 52, color: cs.primary),
                          const SizedBox(height: 10),
                          Text(
                            'No items yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          const Text('Tap “Add item” to add your first item.'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: list.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = list.items[i];

                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            title: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text('Qty: ${item.quantity}'),
                            leading: Checkbox(
                              value: item.bought,
                              onChanged: (_) => _toggleBought(list, item),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemQrScreen(
                                  listId: list.id,
                                  itemId: item.id,
                                  itemName: item.name,
                                  quantity: item.quantity,
                                ),
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Item options',
                              onSelected: (value) async {
                                if (value == 'qr') {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ItemQrScreen(
                                        listId: list.id,
                                        itemId: item.id,
                                        itemName: item.name,
                                        quantity: item.quantity,
                                      ),
                                    ),
                                  );
                                } else if (value == 'qty') {
                                  await _editQuantity(list, item);
                                } else if (value == 'delete') {
                                  await _deleteItem(list, item);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'qr',
                                  child: Text('Show QR'),
                                ),
                                PopupMenuItem(
                                  value: 'qty',
                                  child: Text('Edit quantity'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete item'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
