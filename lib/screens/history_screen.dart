import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_entry.dart';
import '../providers/inventory_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _typeFilter = 'all';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(inventoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nhập/xuất'),
        actions: [
          IconButton(
            tooltip: 'Lọc theo ngày',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
              }
            },
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _typeFilter,
                        decoration: const InputDecoration(labelText: 'Loại giao dịch', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'import', child: Text('Nhập hàng')),
                          DropdownMenuItem(value: 'export', child: Text('Xuất hàng')),
                        ],
                        onChanged: (value) => setState(() => _typeFilter = value ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _dateRange = null),
                        icon: const Icon(Icons.clear),
                        label: const Text('Xoá lọc ngày'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<HistoryEntry>>(
                future: notifier.loadHistory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final all = snapshot.data!
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  final filtered = all.where((entry) {
                    final matchType = _typeFilter == 'all' || entry.type == _typeFilter;
                    final matchDate = _dateRange == null ||
                        (!entry.createdAt.isBefore(_dateRange!.start) &&
                         !entry.createdAt.isAfter(_dateRange!.end.add(const Duration(days: 1))));
                    return matchType && matchDate;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Không có lịch sử phù hợp với bộ lọc.'));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      final isImport = entry.type == 'import';
                      return Card(
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isImport ? Colors.green.shade100 : Colors.orange.shade100,
                            child: Icon(isImport ? Icons.download : Icons.upload, color: isImport ? Colors.green : Colors.orange),
                          ),
                          title: Text('${isImport ? 'Nhập' : 'Xuất'} ${entry.quantity} x ${entry.name}', style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Mã: ${entry.code}'),
                              Text('Thời gian: ${entry.createdAt.toLocal().toString().split('.').first}'),
                            ],
                          ),
                          trailing: Chip(label: Text(isImport ? 'Nhập' : 'Xuất')),
                        ),
                      );
                    },
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
