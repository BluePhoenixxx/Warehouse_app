import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/hive_service.dart';
import '../models/history_entry.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../services/backup_service.dart';
import 'history_screen.dart';
import 'scan_screen.dart';
import 'search_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final backupService = BackupService(HiveInventoryService());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho hàng thông minh'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào! Bạn có ${inventory.length} mặt hàng trong kho.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionCard(
                    icon: Icons.qr_code_scanner,
                    title: 'Nhập hàng',
                    subtitle: 'Quét mã QR hoặc nhập mã để cộng tồn kho',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ScanScreen(mode: 'input'),
                      ),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.output_rounded,
                    title: 'Xuất hàng',
                    subtitle: 'Quét mã QR hoặc nhập mã để trừ tồn kho',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ScanScreen(mode: 'output'),
                      ),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.search,
                    title: 'Tìm kiếm',
                    subtitle: 'Nhập mã hàng để tra cứu',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.bar_chart,
                    title: 'Thống kê',
                    subtitle: 'Số lượng tồn và mặt hàng sắp hết',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.history,
                    title: 'Lịch sử',
                    subtitle: 'Xem và lọc nhập/xuất theo ngày',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final path = await backupService.saveBackupToDevice();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              path == null
                                  ? 'Đã huỷ lưu backup.'
                                  : 'Đã lưu backup tại: $path',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Lưu backup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final path = await backupService.pickBackupFile();
                        if (path == null) return;
                        await backupService.restoreFromFile(path);
                        await ref
                            .read(inventoryProvider.notifier)
                            .loadInventory();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Khôi phục dữ liệu thành công.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Khôi phục'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Tổng quan kho',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _SummaryCard(inventory: inventory),
              const SizedBox(height: 24),
              Text(
                'Lịch sử thêm/xuất gần đây',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<HistoryEntry>>(
                future: ref.read(inventoryProvider.notifier).recentHistory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final history = snapshot.data!.take(6).toList();
                  if (history.isEmpty) {
                    return const Card(
                      child: ListTile(
                        title: Text('Chưa có lịch sử nhập/xuất.'),
                      ),
                    );
                  }
                  return Column(
                    children: history.map((entry) {
                      final isImport = entry.type == 'import';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isImport
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            child: Icon(
                              isImport ? Icons.download : Icons.upload,
                              color: isImport ? Colors.green : Colors.orange,
                            ),
                          ),
                          title: Text(
                            '${isImport ? 'Nhập' : 'Xuất'} ${entry.quantity} x ${entry.name}',
                          ),
                          subtitle: Text(
                            'Mã: ${entry.code} • ${entry.createdAt.toLocal().toString().split('.').first}',
                          ),
                          trailing: Chip(
                            label: Text(isImport ? 'Nhập' : 'Xuất'),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Mặt hàng gần đây',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              inventory.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Chưa có dữ liệu kho. Hãy quét mã QR để bắt đầu.',
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inventory.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = inventory[index];
                        return Card(
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.quantity < 5
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: item.quantity < 5
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              'Mã: ${item.code} • Cập nhật: ${item.updatedAt.toLocal().toString().split('.').first}',
                            ),
                            trailing: Chip(
                              label: Text('Tồn: ${item.quantity}'),
                              backgroundColor: item.quantity < 5
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.inventory});

  final List<InventoryItem> inventory;

  @override
  Widget build(BuildContext context) {
    final total = inventory.fold<int>(0, (sum, item) => sum + item.quantity);
    final low = inventory.where((item) => item.quantity < 5).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _MiniStat(
                title: 'Tổng tồn',
                value: total.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                title: 'Sắp hết',
                value: low.toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                title: 'Mặt hàng',
                value: inventory.length.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
