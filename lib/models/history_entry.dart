class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.type,
    required this.code,
    required this.name,
    required this.quantity,
    required this.createdAt,
  });

  final String id;
  final String type; // import / export
  final String code;
  final String name;
  final int quantity;
  final DateTime createdAt;

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as String,
      type: map['type'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'code': code,
      'name': name,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
