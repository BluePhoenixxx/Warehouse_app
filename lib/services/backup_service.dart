import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/hive_service.dart';
import '../models/inventory_item.dart';

class BackupService {
  BackupService(this._hiveService);

  final HiveInventoryService _hiveService;

  Future<String> createBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/warehouse_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    final items = await _hiveService.exportItems();
    await file.writeAsString(jsonEncode(items));
    return file.path;
  }

  Future<String?> saveBackupToDevice() async {
    final items = await _hiveService.exportItems();
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(items)));

    final path = await FilePicker.saveFile(
      dialogTitle: 'Lưu file backup kho hàng',
      fileName: 'warehouse_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    return path;
  }

  Future<void> shareBackup(String path) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Backup dữ liệu kho hàng'),
    );
  }

  Future<String?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    return result?.files.single.path;
  }

  Future<void> restoreFromFile(String path) async {
    final raw = await File(path).readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException('File backup không hợp lệ');
    }

    final items = decoded
        .map((item) => InventoryItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    await _hiveService.restoreItems(items);
  }
}
