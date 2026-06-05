import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, required this.mode});

  final String mode;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  String? _lastCode;
  bool _isScannerActive = false;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  List<InventoryItem> _suggestedItems = [];
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'input' ? 'Nhập hàng' : 'Xuất hàng'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isScannerActive)
              SizedBox(
                height: 320,
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
    final value = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (value == null) return;

    // If the value is the same as the last code, do nothing.
    // This prevents duplicate processing if the scanner is held over the same code.
    if (value == _lastCode) return;

    _handleScannedCode(value);
  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mode == 'input'
                        ? 'Hướng dẫn: Nhập mã, tên và số lượng rồi quét mã QR hoặc dùng nút bên dưới để thao tác bằng tay.'
                        : 'Hướng dẫn: Nhập mã và số lượng rồi quét mã QR hoặc dùng nút bên dưới để xuất hàng bằng tay.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    onChanged: _updateSuggestions,
                    decoration: const InputDecoration(
                      labelText: 'Mã sản phẩm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_suggestedItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Gợi ý mã đã có:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedItems
                          .map(
                            (item) => ActionChip(
                              label: Text('${item.code} • ${item.name}'),
                              onPressed: () => _applySuggestion(item),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: widget.mode == 'input'
                          ? 'Tên sản phẩm (tuỳ chọn)'
                          : 'Tên sản phẩm (nếu cần)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.mode == 'input'
                          ? 'Số lượng nhập'
                          : 'Số lượng xuất',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_codeController.text.trim().isNotEmpty)
                    Builder(
                      builder: (context) {
                        final code = _codeController.text.trim();
                        final existing = ref
                            .read(inventoryProvider.notifier)
                            .getItemByCode(code);
                        if (existing == null) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã có mã này: ${existing.name} • Tồn hiện tại: ${existing.quantity}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _handleManualAction,
                      icon: Icon(
                        widget.mode == 'input' ? Icons.add : Icons.remove,
                      ),
                      label: Text(
                        widget.mode == 'input'
                            ? 'Nhập bằng mã'
                            : 'Xuất bằng mã',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_lastCode != null)
                    Text(
                      'Mã vừa quét: $_lastCode',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _handleManualAction(popAfter: true),
                      icon: const Icon(Icons.done),
                      label: const Text('Hoàn tất'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _isScannerActive = !_isScannerActive;
                          if (_isScannerActive) {
                            _scannerController.start();
                          } else {
                            _scannerController.stop();
                          }
                        });
                      },
                      icon: Icon(
                        _isScannerActive ? Icons.qr_code_scanner : Icons.qr_code,
                      ),
                      label: Text(
                        _isScannerActive ? 'Tắt quét QR' : 'Bật quét QR',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleManualAction({bool popAfter = false}) async {
    final code = _codeController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    if (code.isEmpty) {
      _showSnackBar('Vui lòng nhập mã sản phẩm.');
      return;
    }
    if (quantity <= 0) {
      _showSnackBar('Số lượng phải lớn hơn 0.');
      return;
    }

    setState(() => _lastCode = code);

    final existingItem = ref.read(inventoryProvider.notifier).getItemByCode(code);

    if (widget.mode == 'input') {
      final name = _nameController.text.trim().isEmpty
          ? (existingItem != null ? existingItem.name : 'Sản phẩm $code')
          : _nameController.text.trim();
      await ref.read(inventoryProvider.notifier).addStock(code, name, quantity);
      _showSnackBar('Đã nhập $quantity sản phẩm: $code');
    } else {
      final success = await ref
          .read(inventoryProvider.notifier)
          .removeStock(code, quantity);
      if (!success) {
        _showSnackBar('Không tồn tại hoặc số lượng xuất vượt tồn kho.');
        return;
      } else {
        _showSnackBar('Đã xuất $quantity sản phẩm: $code');
      }
    }

    if (popAfter && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleScannedCode(String value) async {
    String primaryCode = '';
    String secondaryCode = ''; // To store the '39ESRPWVH923' part if present
    String name = '';

    // Split the scanned value by '|' to get individual components.
    final parts = value.split('|');
    if (parts.length >= 12) { // Assuming the format is consistent with the example
      primaryCode = parts[0]; // e.g., '4011530'
      name = parts[1]; // e.g., 'Tụ điện'
      secondaryCode = parts[11]; // e.g., '39ESRPWVH923'
    } else {
      // If the format is not as expected, treat the whole value as the primary code.
      primaryCode = value;
    }

    final existing = ref.read(inventoryProvider.notifier).getItemByCode(primaryCode);
    setState(() {
      _isScannerActive = false;
      _scannerController.stop();
      _lastCode = primaryCode; // Display the primary code as the last scanned code
      _codeController.text = primaryCode; // Set the primary code in the input field

      if (existing != null) {
        _nameController.text = existing.name;
      } else if (name.isNotEmpty) {
        _nameController.text = name;
      }
    });
    _showSnackBar('Đã quét mã: $primaryCode. Vui lòng kiểm tra thông tin và nhấn nút để hoàn tất.');
  }

  void _updateSuggestions(String value) {
    final suggestions = ref
        .read(inventoryProvider.notifier)
        .suggestItems(value);
    
    // Check if there is an exact match for code or QR code
    final exactMatch = ref.read(inventoryProvider.notifier).getItemByCode(value);

    setState(() {
      _suggestedItems = suggestions;
      if (exactMatch != null) {
        _nameController.text = exactMatch.name;
      }
    });
  }

  void _applySuggestion(InventoryItem item) {
    setState(() {
      _codeController.text = item.code;
      _nameController.text = item.name;
      _lastCode = item.code;
      _quantityController.text = '1'; // Keep default quantity as 1 for adding/subtracting
      _suggestedItems = [];
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
