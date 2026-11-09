import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';

void main() {
  const ios = TargetPlatformVariant({TargetPlatform.iOS});

  for (final grouped in [false, true]) {
    testWidgets('restores glass after nested modal exits (grouped: $grouped)',
        (tester) async {
      final rootNavigator = GlobalKey<NavigatorState>();
      final innerNavigator = GlobalKey<NavigatorState>();
      final enabled = ValueNotifier(true);
      addTearDown(enabled.dispose);
      final fieldKey = GlobalKey();
      final card = ValueListenableBuilder(
        valueListenable: enabled,
        builder: (context, value, child) => LiquidGlassCard(
          nativeGlassEnabled: value,
          child: child!,
        ),
        child: TextField(key: fieldKey),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigator,
          navigatorObservers: [LiquidGlassRouteObserver()],
          home: Navigator(
            key: innerNavigator,
            observers: [LiquidGlassRouteObserver()],
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                body: grouped ? LiquidGlassBackdropGroup(child: card) : card,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final nativeView = find.byType(UiKitView);
      final field = find.byKey(fieldKey);
      final element = tester.element(field);
      final size = tester.getSize(field);
      await tester.enterText(field, 'draft');
      expect(nativeView, findsOneWidget);

      enabled.value = false;
      await tester.pumpAndSettle();
      // A grouped card unregisters its surface from the shared host.
      expect(nativeView, grouped ? findsOneWidget : findsNothing);
      expect(tester.element(field), same(element));
      enabled.value = true;
      await tester.pumpAndSettle();

      showModalBottomSheet<void>(
        context: element,
        builder: (_) => const SizedBox(height: 200),
      );
      await tester.pumpAndSettle();
      expect(nativeView, findsNothing);
      showDialog<void>(
        context: element,
        builder: (_) => const AlertDialog(title: Text('Root dialog')),
      );
      await tester.pumpAndSettle();

      // Dismiss the inner sheet while a route on the root still covers it.
      innerNavigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(nativeView, findsNothing);
      rootNavigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(nativeView, findsNothing);
      await tester.pumpAndSettle();

      expect(nativeView, findsOneWidget);
      expect(tester.element(field), same(element));
      expect(tester.getSize(field), size);
      expect(find.text('draft'), findsOneWidget);

      const sheetKey = ValueKey('draggable sheet');
      showModalBottomSheet<void>(
        context: element,
        builder: (_) => const SizedBox(
          key: sheetKey,
          height: 200,
          width: double.infinity,
          child: ColoredBox(color: Colors.white),
        ),
      );
      await tester.pumpAndSettle();
      final sheet = find.byKey(sheetKey);
      final dragStart = tester.getTopLeft(sheet) + const Offset(100, 10);
      await tester.dragFrom(dragStart, const Offset(0, 170));
      await tester.pumpAndSettle();
      expect(find.byKey(sheetKey), findsNothing);
      expect(nativeView, findsOneWidget);
    }, variant: ios);
  }

  testWidgets('keeps glass suppressed during a pushed page and its exit',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [LiquidGlassRouteObserver()],
      home: const Scaffold(body: LiquidGlassCard(child: Text('Glass'))),
    ));

    final nativeView = find.byType(UiKitView, skipOffstage: false);
    expect(nativeView, findsOneWidget);
    navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Next page')),
    ));
    await tester.pumpAndSettle();
    expect(nativeView, findsNothing);

    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(nativeView, findsNothing);
    await tester.pumpAndSettle();
    expect(nativeView, findsOneWidget);
  }, variant: ios);
}
