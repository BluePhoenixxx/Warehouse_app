import 'package:hive/hive.dart';

import '../models/history_entry.dart';
import '../models/inventory_item.dart';

class HiveInventoryService {
  static const String _boxName = 'inventory_box';
  static const String _historyBoxName = 'history_box';

  Future<Box<Map>> openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  Future<List<InventoryItem>> loadItems() async {
    final box = await openBox();
    return box.values
        .map((raw) => InventoryItem.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<void> saveItem(InventoryItem item) async {
    final box = await openBox();
    await box.put(item.code, item.toMap());
  }

  Future<void> deleteItem(String code) async {
    final box = await openBox();
    await box.delete(code);
  }

  Future<Box<Map>> openHistoryBox() async {
    if (!Hive.isBoxOpen(_historyBoxName)) {
      return Hive.openBox<Map>(_historyBoxName);
    }
    return Hive.box<Map>(_historyBoxName);
  }

  Future<List<HistoryEntry>> loadHistory() async {
    final box = await openHistoryBox();
    return box.values
        .map((raw) => HistoryEntry.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<void> addHistory(HistoryEntry entry) async {
    final box = await openHistoryBox();
    await box.put(entry.id, entry.toMap());
  }

  Future<List<Map<String, dynamic>>> exportItems() async {
    final box = await openBox();
    return box.values
        .map((raw) => Map<String, dynamic>.from(raw))
        .toList();
  }

  Future<void> restoreItems(List<InventoryItem> items) async {
    final box = await openBox();
    await box.clear();
    for (final item in items) {
      await box.put(item.code, item.toMap());
    }
  }
}
