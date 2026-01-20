import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/shopping_list.dart';
import '../storage/keys.dart';
import 'list_detail_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  Box get _box => Hive.box(HiveKeys.listsBox);

  List<ShoppingListModel> _loadLists() {
    final raw = _box.values.toList();
    final lists =
        raw
            .map((e) => ShoppingListModel.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lists;
  }

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

    if (title == null || title.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final list = ShoppingListModel(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      items: [],
    );

    await _box.put(id, list.toMap());
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteList(String id) async {
    await _box.delete(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lists = _loadLists();

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Lists')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        child: const Icon(Icons.add),
      ),
      body: lists.isEmpty
          ? const Center(child: Text('No lists yet. Tap + to create one.'))
          : ListView.builder(
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
                    setState(() {});
                  },
                  trailing: IconButton(
                    tooltip: 'Delete list',
                    onPressed: () => _deleteList(l.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              },
            ),
    );
  }
}
