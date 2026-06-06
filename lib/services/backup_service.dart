import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/hive_service.dart';
import '../models/history_entry.dart';
import '../models/inventory_item.dart';

class BackupService {
  BackupService(this._hiveService);

  final HiveInventoryService _hiveService;

  Future<String> createBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/warehouse_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    final items = await _hiveService.exportItems();
    final history = await _hiveService.exportHistory();
    await file.writeAsString(jsonEncode({'items': items, 'history': history}));
    return file.path;
  }

  Future<String?> saveBackupToDevice() async {
    final items = await _hiveService.exportItems();
    final history = await _hiveService.exportHistory();
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'items': items, 'history': history})));

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu file backup kho hàng',
      fileName: 'warehouse_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    return path;
  }

  Future<void> shareBackup(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File không tồn tại: $path');
    }
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Backup dữ liệu kho hàng',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    );
  }

  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    return result?.files.singleOrNull?.path;
  }

  Future<void> restoreFromFile(String path) async {
    final raw = await File(path).readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is! Map || !decoded.containsKey('items') || !decoded.containsKey('history')) {
      // Fallback for old format (List)
      if (decoded is List) {
        final items = decoded
            .map((item) => InventoryItem.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        await _hiveService.restoreItems(items);
        return;
      }
      throw const FormatException('File backup không hợp lệ');
    }

    final items = (decoded['items'] as List)
        .map((item) => InventoryItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
    final history = (decoded['history'] as List)
        .map((entry) => HistoryEntry.fromMap(Map<String, dynamic>.from(entry as Map)))
        .toList();

    await _hiveService.restoreItems(items);
    await _hiveService.restoreHistory(history);
  }
}
