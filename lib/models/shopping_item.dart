class ShoppingItem {
  final String id;
  final String name;
  int quantity;
  bool bought;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.bought = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'bought': bought,
  };

  static ShoppingItem fromMap(Map map) => ShoppingItem(
    id: map['id'] as String,
    name: map['name'] as String,
    quantity: (map['quantity'] as int?) ?? 1,
    bought: (map['bought'] as bool?) ?? false,
  );
}
