import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inventory_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryProvider);
    final result = ref.read(inventoryProvider.notifier).search(_controller.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm mã hàng')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nhập mã hoặc tên hàng',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: result.isEmpty
                  ? const Center(child: Text('Không tìm thấy mặt hàng phù hợp.'))
                  : ListView.builder(
                      itemCount: result.length,
                      itemBuilder: (context, index) {
                        final item = result[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mã: ${item.code}'),
                                if (item.qrCodes.isNotEmpty)
                                  Text(
                                    'Mã QR liên kết: ${item.qrCodes.join(", ")}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                            trailing: Chip(label: Text('Tồn: ${item.quantity}')),
                          ),
                        );
                      },
                    ),
            ),
            Text('Tổng mặt hàng hiện có: ${items.length}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
