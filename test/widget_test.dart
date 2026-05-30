// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/main.dart';
import 'package:warehouse_app/models/history_entry.dart';
import 'package:warehouse_app/models/inventory_item.dart';
import 'package:warehouse_app/providers/inventory_provider.dart';

class TestInventoryNotifier extends InventoryNotifier {
  @override
  List<InventoryItem> build() => [];

  @override
  Future<List<HistoryEntry>> recentHistory() async => [];
}

void main() {
  testWidgets('Warehouse app loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith(() => TestInventoryNotifier()),
        ],
        child: const WarehouseApp(),
      ),
    );

    expect(find.text('Kho hàng thông minh'), findsOneWidget);
    expect(find.text('Warehouse App is ready!'), findsNothing);
  });
}
