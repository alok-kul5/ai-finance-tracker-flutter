import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/app.dart';
import 'package:kharcha/data/memory_store.dart';
import 'package:kharcha/domain/models.dart';
import 'package:kharcha/platform/demo_data.dart';
import 'package:kharcha/platform/web_services.dart' as demo;
import 'package:kharcha/state/providers.dart';
import 'package:kharcha/widgets/ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final now = DateTime(2026, 11, 20, 18);

  Future<MemoryLedgerStore> pumpApp(WidgetTester tester, {bool seed = true}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryLedgerStore(clock: () => now);
    if (seed) store.seed(txns: demoTxns(now), budgets: demoBudgets());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        servicesProvider.overrideWithValue(demo.createServices()),
        storeProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const KharchaApp(),
    ));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('home shows this month, budgets and recent rows', (tester) async {
    await pumpApp(tester);
    expect(find.text('Kharcha'), findsOneWidget);
    expect(find.text('Spent this month'), findsOneWidget);
    expect(find.text('Budgets'), findsWidgets);
    expect(find.byType(GlassTabBar), findsOneWidget);
  });

  testWidgets('empty ledger shows the empty state', (tester) async {
    await pumpApp(tester, seed: false);
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('tabs switch and the activity search filters', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Search merchants, categories'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'netflix');
    await tester.pumpAndSettle();
    expect(find.text('Netflix'), findsWidgets);
    expect(find.text('Swiggy'), findsNothing);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Last six months'), findsOneWidget);
  });

  testWidgets('Ask answers with numbers computed from the store', (tester) async {
    final store = await pumpApp(tester, seed: false);
    await store.saveTxn(Txn(
      id: 'a',
      amountPaise: 45000,
      direction: TxnDirection.debit,
      occurredAt: DateTime(2026, 11, 3),
      merchant: 'Swiggy',
      category: 'Food & Dining',
      source: TxnSource.sms,
    ));
    await store.saveTxn(Txn(
      id: 'b',
      amountPaise: 30050,
      direction: TxnDirection.debit,
      occurredAt: DateTime(2026, 11, 9),
      merchant: 'Zomato',
      category: 'Food & Dining',
      source: TxnSource.sms,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How much did I spend on food this month?'));
    await tester.pumpAndSettle();
    expect(find.text('You spent ₹750.50 on Food & Dining this month, across 2 transactions.'), findsOneWidget);
    expect(find.text('Read by rules'), findsOneWidget);
  });

  testWidgets('manual add goes through the editor and is auto-categorised', (tester) async {
    final store = await pumpApp(tester, seed: false);
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '249');
    await tester.enterText(find.byType(TextField).at(1), 'Uber');
    await tester.ensureVisible(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    final saved = (await store.txns()).single;
    expect(saved.amountPaise, 24900);
    expect(saved.category, 'Transport');
    expect(saved.categorySource, 'rule');
  });

  testWidgets('dark theme builds', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    final ctx = tester.element(find.byType(HomeShell));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });
}
