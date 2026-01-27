import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/analytics_service.dart';

import '../storage/keys.dart';
import '../models/shopping_list.dart';
import 'list_detail_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  Box get _box => Hive.box(HiveKeys.listsBox);

  Future<void> _createList() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create list'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'List name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (title == null || title.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final list = ShoppingListModel(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      items: [],
    );

    // No setState needed: ValueListenableBuilder will rebuild when the box changes
    await _box.put(id, list.toMap());
    await AnalyticsService.instance.logCreateList();
  }

  Future<void> _deleteList(String id) async {
    // No setState needed: ValueListenableBuilder will rebuild when the box changes
    await _box.delete(id);
  }

  List<ShoppingListModel> _listsFromBox(Box box) {
    final raw = box.values.toList();
    final lists =
        raw
            .map((e) => ShoppingListModel.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Lists')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box box, _) {
          final lists = _listsFromBox(box);

          if (lists.isEmpty) {
            return const Center(
              child: Text('No lists yet. Tap + to create one.'),
            );
          }

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (_, i) {
              final l = lists[i];
              final total = l.items.length;
              final bought = l.items.where((x) => x.bought).length;

              return ListTile(
                title: Text(l.title),
                subtitle: Text('$bought / $total bought'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListDetailScreen(listId: l.id),
                    ),
                  );
                  // No setState needed: detail screen updates Hive; listener will rebuild when you return
                },
                trailing: IconButton(
                  tooltip: 'Delete list',
                  onPressed: () => _deleteList(l.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
