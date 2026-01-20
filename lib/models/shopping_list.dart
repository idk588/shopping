import 'shopping_item.dart';

class ShoppingListModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ShoppingItem> items;

  ShoppingListModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.items,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((e) => e.toMap()).toList(),
  };

  static ShoppingListModel fromMap(Map map) => ShoppingListModel(
    id: map['id'] as String,
    title: map['title'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    items: (map['items'] as List)
        .map((e) => ShoppingItem.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
  );
}
