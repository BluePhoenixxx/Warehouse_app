class InventoryItem {
  InventoryItem({
    required this.code,
    required this.name,
    required this.quantity,
    required this.updatedAt,
    this.qrCodes = const [],
  });

  final String code;
  final String name;
  final int quantity;
  final DateTime updatedAt;
  final List<String> qrCodes;

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      code: map['code'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      qrCodes: map['qrCodes'] != null
          ? List<String>.from(map['qrCodes'] as List)
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'quantity': quantity,
      'updatedAt': updatedAt.toIso8601String(),
      'qrCodes': qrCodes,
    };
  }
}
