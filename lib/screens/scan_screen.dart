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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'input' ? 'Nhập hàng bằng QR' : 'Xuất hàng bằng QR'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 320,
              child: MobileScanner(
                onDetect: (capture) {
                final value = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                if (value == null || value == _lastCode) return;

                setState(() => _lastCode = value);
                final quantity = int.tryParse(_quantityController.text) ?? 1;

                if (widget.mode == 'input') {
                  final name = _nameController.text.trim().isEmpty
                      ? 'Sản phẩm $value'
                      : _nameController.text.trim();
                  ref.read(inventoryProvider.notifier).addStock(value, name, quantity);
                  _showSnackBar('Đã lưu mã QR: $value (x$quantity)');
                  return;
                }

                Future.microtask(() async {
                  final success = await ref.read(inventoryProvider.notifier).removeStock(value, quantity);
                  if (!success) {
                    _showSnackBar('Không tồn tại hoặc số lượng xuất vượt tồn kho.');
                  } else {
                    _showSnackBar('Đã xuất $quantity sản phẩm: $value');
                  }
                });
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
                        ? 'Hướng dẫn: Nhập tên và số lượng trước khi quét để lưu mã QR vào kho.'
                        : 'Hướng dẫn: Quét mã QR của sản phẩm để giảm tồn kho.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                      labelText: widget.mode == 'input' ? 'Số lượng nhập' : 'Số lượng xuất',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_lastCode != null)
                    Text('Mã vừa quét: $_lastCode', style: Theme.of(context).textTheme.bodyLarge),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
