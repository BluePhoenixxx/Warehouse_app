import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inventory_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(inventoryProvider.notifier);
    final items = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê tồn kho')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Tổng tồn', value: notifier.totalQuantity.toString(), accent: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'Sắp hết (< 5)', value: notifier.lowStockItems.toString(), accent: Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            _StatCard(title: 'Tổng mặt hàng', value: items.length.toString(), accent: Colors.green),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final lowStock = item.quantity < 5;
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: lowStock ? Colors.orange.shade100 : Colors.green.shade100,
                        child: Icon(Icons.inventory_2_outlined, color: lowStock ? Colors.orange : Colors.green),
                      ),
                      title: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Mã: ${item.code}', style: Theme.of(context).textTheme.bodyMedium),
                          if (item.qrCodes.isNotEmpty)
                            Text(
                              'Mã QR liên kết: ${item.qrCodes.join(", ")}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          Text('Cập nhật: ${item.updatedAt.toLocal().toString().split('.').first}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      trailing: Chip(
                        label: Text('Tồn ${item.quantity}'),
                        backgroundColor: lowStock ? Colors.orange.shade100 : Colors.green.shade100,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.accent});

  final String title;
  final String value;
  final MaterialColor accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accent.shade100,
              child: Icon(Icons.pie_chart_outline, color: accent.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
