import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/hive_service.dart';
import '../models/history_entry.dart';
import '../models/inventory_item.dart';

final inventoryProvider =
    NotifierProvider<InventoryNotifier, List<InventoryItem>>(() {
      return InventoryNotifier();
    });

class InventoryNotifier extends Notifier<List<InventoryItem>> {
  final HiveInventoryService _service = HiveInventoryService();

  @override
  List<InventoryItem> build() {
    loadInventory();
    return [];
  }

  Future<void> loadInventory() async {
    state = await _service.loadItems();
  }

  Future<void> addStock(String code, String name, int quantity) async {
    final existing = state.where((item) => item.code == code).isNotEmpty
        ? state.firstWhere((item) => item.code == code)
        : null;

    if (existing != null) {
      final updated = InventoryItem(
        code: existing.code,
        name: existing.name,
        quantity: existing.quantity + quantity,
        updatedAt: DateTime.now(),
      );
      await _service.saveItem(updated);
    } else {
      final created = InventoryItem(
        code: code,
        name: name.isEmpty ? 'Sản phẩm $code' : name,
        quantity: quantity,
        updatedAt: DateTime.now(),
      );
      await _service.saveItem(created);
    }

    await _service.addHistory(
      HistoryEntry(
        id: 'import_${DateTime.now().millisecondsSinceEpoch}',
        type: 'import',
        code: code,
        name: name.isEmpty ? 'Sản phẩm $code' : name,
        quantity: quantity,
        createdAt: DateTime.now(),
      ),
    );

    await loadInventory();
  }

  Future<bool> removeStock(String code, int quantity) async {
    final existing = state.where((item) => item.code == code).isNotEmpty
        ? state.firstWhere((item) => item.code == code)
        : null;

    if (existing == null || quantity <= 0 || existing.quantity < quantity) {
      return false;
    }

    final nextQuantity = existing.quantity - quantity;
    if (nextQuantity <= 0) {
      await _service.deleteItem(code);
    } else {
      final updated = InventoryItem(
        code: existing.code,
        name: existing.name,
        quantity: nextQuantity,
        updatedAt: DateTime.now(),
      );
      await _service.saveItem(updated);
    }

    await _service.addHistory(
      HistoryEntry(
        id: 'export_${DateTime.now().millisecondsSinceEpoch}',
        type: 'export',
        code: existing.code,
        name: existing.name,
        quantity: quantity,
        createdAt: DateTime.now(),
      ),
    );

    await loadInventory();
    return true;
  }

  Future<List<HistoryEntry>> loadHistory() async => _service.loadHistory();

  InventoryItem? getItemByCode(String code) {
    final normalized = code.trim();
    for (final item in state) {
      if (item.code == normalized) return item;
    }
    return null;
  }

  List<InventoryItem> suggestItems(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return [];

    return state.where((item) {
      return item.code.toLowerCase().contains(value) ||
          item.name.toLowerCase().contains(value);
    }).toList();
  }

  List<InventoryItem> search(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return state;

    return state.where((item) {
      return item.code.toLowerCase().contains(value) ||
          item.name.toLowerCase().contains(value);
    }).toList();
  }

  int get totalQuantity =>
      state.fold<int>(0, (sum, item) => sum + item.quantity);

  int get lowStockItems => state.where((item) => item.quantity < 5).length;

  Future<List<HistoryEntry>> recentHistory() async => _service.loadHistory();
}
