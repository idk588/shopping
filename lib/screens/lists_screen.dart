import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/keys.dart';
import '../models/shopping_list.dart';
import '../ui/ui.dart';
import 'list_detail_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  Box get _box => Hive.box(HiveKeys.listsBox);

  List<ShoppingListModel> _listsFromBox(Box box) {
    final raw = box.values.toList();
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
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

    await _box.put(id, list.toMap());
  }

  Future<void> _deleteList(String id) async {
    await _box.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Lists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createList,
        icon: const Icon(Icons.add),
        label: const Text('New list'),
      ),
      body: Padding(
        padding: Ui.screenPadding,
        child: ValueListenableBuilder(
          valueListenable: _box.listenable(),
          builder: (context, Box box, _) {
            final lists = _listsFromBox(box);

            if (lists.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt, size: 52, color: cs.primary),
                    Ui.gap12,
                    Text(
                      'No lists yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Ui.gap8,
                    Text(
                      'Tap “New list” to create your first one.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: lists.length,
              separatorBuilder: (_, __) => Ui.gap12,
              itemBuilder: (_, i) {
                final l = lists[i];
                final total = l.items.length;
                final bought = l.items.where((x) => x.bought).length;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    title: Text(
                      l.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text('$bought / $total bought'),
                    leading: CircleAvatar(
                      backgroundColor: Color.fromARGB(
                        (0.12 * 255).round(),
                        cs.primary.r.toInt(),
                        cs.primary.g.toInt(),
                        cs.primary.b.toInt(),
                      ),
                      foregroundColor: cs.primary,
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete list',
                      onPressed: () => _deleteList(l.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListDetailScreen(listId: l.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
