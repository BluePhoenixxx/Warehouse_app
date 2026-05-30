import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/inventory_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, required this.mode});

  final String mode;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  String? _lastCode;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  List<InventoryItem> _suggestedItems = [];

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
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
            SizedBox(
              height: 320,
              child: MobileScanner(
                onDetect: (capture) {
                  final value = capture.barcodes.isNotEmpty
                      ? capture.barcodes.first.rawValue
                      : null;
                  if (value == null || value == _lastCode) return;
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.done),
                      label: const Text('Hoàn tất'),
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

  Future<void> _handleManualAction() async {
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
    if (widget.mode == 'input') {
      final name = _nameController.text.trim().isEmpty
          ? 'Sản phẩm $code'
          : _nameController.text.trim();
      await ref.read(inventoryProvider.notifier).addStock(code, name, quantity);
      _showSnackBar('Đã nhập $quantity sản phẩm: $code');
      return;
    }

    final success = await ref
        .read(inventoryProvider.notifier)
        .removeStock(code, quantity);
    if (!success) {
      _showSnackBar('Không tồn tại hoặc số lượng xuất vượt tồn kho.');
    } else {
      _showSnackBar('Đã xuất $quantity sản phẩm: $code');
    }
  }

  Future<void> _handleScannedCode(String value) async {
    final existing = ref.read(inventoryProvider.notifier).getItemByCode(value);
    setState(() {
      _lastCode = value;
      _codeController.text = value;
      if (existing != null) {
        _nameController.text = existing.name;
      }
    });

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (widget.mode == 'input') {
      final name = existing != null
          ? existing.name
          : _nameController.text.trim().isEmpty
          ? 'Sản phẩm $value'
          : _nameController.text.trim();
      await ref
          .read(inventoryProvider.notifier)
          .addStock(value, name, quantity);
      _showSnackBar('Đã lưu mã QR: $value (x$quantity)');
      return;
    }

    final success = await ref
        .read(inventoryProvider.notifier)
        .removeStock(value, quantity);
    if (!success) {
      _showSnackBar('Không tồn tại hoặc số lượng xuất vượt tồn kho.');
    } else {
      _showSnackBar('Đã xuất $quantity sản phẩm: $value');
    }
  }

  void _updateSuggestions(String value) {
    final suggestions = ref
        .read(inventoryProvider.notifier)
        .suggestItems(value);
    setState(() {
      _suggestedItems = suggestions;
    });
  }

  void _applySuggestion(InventoryItem item) {
    setState(() {
      _codeController.text = item.code;
      _nameController.text = item.name;
      _lastCode = item.code;
      _suggestedItems = [];
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
