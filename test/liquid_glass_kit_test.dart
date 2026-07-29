import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';
import 'package:flutter_liquid_glass_kit/src/fallback_glass.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('routes only iOS to the native surface', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(isNativeLiquidGlassSupported, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(isNativeLiquidGlassSupported, isTrue);
  });

  test('settings preserve a supplied Android glass colour', () {
    const colour = Color(0xFF6750A4);
    const settings = LiquidGlassSettings(tintColor: colour, tintOpacity: 0.3);

    final updated = settings.copyWith(blurSigma: 28);

    expect(updated.tintColor, colour);
    expect(updated.tintOpacity, 0.3);
    expect(updated.blurSigma, 28);
  });

  test('equivalent settings use value equality', () {
    const first = LiquidGlassSettings(
      tintColor: Colors.blue,
      tintOpacity: 0.3,
    );
    const second = LiquidGlassSettings(
      tintColor: Colors.blue,
      tintOpacity: 0.3,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('nav scroll configuration has stable defaults and equality', () {
    const first = LiquidGlassNavBarScrollConfiguration();
    const second = LiquidGlassNavBarScrollConfiguration();

    expect(first.collapsedScale, 0.82);
    expect(first.collapseThreshold, 12);
    expect(first.animationDuration, const Duration(milliseconds: 280));
    expect(first.idleExpandDuration, const Duration(seconds: 5));
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  testWidgets('floating nav bar handles safe area and platform spacing', (
    tester,
  ) async {
    late BuildContext buildContext;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: 34),
        ),
        child: Builder(
          builder: (context) {
            buildContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final navBar = LiquidGlassNavBar(
      currentIndex: 0,
      onTap: _noop,
      items: _navItems,
    );
    final floatingNavBar = LiquidGlassFloatingNavBar(child: navBar);

    expect(navBar.build(buildContext), isNot(isA<Positioned>()));

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final androidPosition = floatingNavBar.build(buildContext) as Positioned;
    expect(androidPosition.bottom, 50);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final iosPosition = floatingNavBar.build(buildContext) as Positioned;
    expect(iosPosition.bottom, 34);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('glass scroll behavior removes overscroll indicators', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Placeholder(),
      ),
    );

    final context = tester.element(find.byType(Placeholder));
    const child = SizedBox(width: 80, height: 40);
    const behavior = LiquidGlassScrollBehavior();
    final details = ScrollableDetails(
      direction: AxisDirection.down,
      controller: ScrollController(),
    );

    expect(
      behavior.buildOverscrollIndicator(context, child, details),
      same(child),
    );

    details.controller?.dispose();
  });

  testWidgets('uses the Flutter fallback on Android', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlatformGlass(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          child: SizedBox(width: 80, height: 40),
        ),
      ),
    );

    expect(find.byType(FallbackGlass), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('grouped Android glass skips blur while scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: LiquidGlassBackdropGroup(
              child: ListView.builder(
                itemCount: 12,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: FallbackGlass(
                    borderRadius: BorderRadius.circular(16),
                    settings: LiquidGlassSettings.matteLight,
                    child: const SizedBox(height: 72),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsWidgets);
    final initialKey = tester
        .widget<BackdropGroup>(
          find.byType(BackdropGroup),
        )
        .backdropKey;

    final gesture = await tester.startGesture(const Offset(200, 180));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();

    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      tester.widget<BackdropGroup>(find.byType(BackdropGroup)).backdropKey,
      same(initialKey),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsWidgets);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('components inherit group settings and allow local overrides', (
    tester,
  ) async {
    const sharedSettings = LiquidGlassSettings(
      tintColor: Colors.blue,
      tintOpacity: 0.32,
    );
    const localSettings = LiquidGlassSettings(
      tintColor: Colors.green,
      tintOpacity: 0.4,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassBackdropGroup(
          settings: sharedSettings,
          child: Scaffold(
            body: Stack(
              children: [
                const Positioned(
                  top: 20,
                  left: 20,
                  child: LiquidGlassCard(
                    key: ValueKey('card'),
                    child: Text('Card'),
                  ),
                ),
                const Positioned(
                  top: 100,
                  left: 20,
                  child: LiquidGlassButton(
                    key: ValueKey('button'),
                    onPressed: _noopVoid,
                    child: Text('Button'),
                  ),
                ),
                const Positioned(
                  top: 180,
                  left: 20,
                  child: PlatformGlass(
                    key: ValueKey('platform'),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    child: SizedBox(width: 80, height: 40),
                  ),
                ),
                LiquidGlassNavBar(
                  key: const ValueKey('nav'),
                  currentIndex: 0,
                  onTap: _noop,
                  settings: localSettings,
                  items: _navItems,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final key in ['card', 'button', 'platform']) {
      expect(_fallbackSettingsUnder(tester, key), sharedSettings);
    }
    expect(_fallbackSettingsUnder(tester, 'nav'), localSettings);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('matteDark inherits through a group and paints a dark surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LiquidGlassSettingsScope(
          settings: LiquidGlassSettings.matteDark,
          child: LiquidGlassBackdropGroup(
            child: Center(
              child: LiquidGlassCard(
                key: ValueKey('dark-card'),
                child: SizedBox(width: 120, height: 60),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      _fallbackSettingsUnder(tester, 'dark-card'),
      LiquidGlassSettings.matteDark,
    );

    final decoration = _glassDecorationUnder(tester, 'dark-card');
    final gradient = decoration.gradient! as LinearGradient;

    expect(
      decoration.color,
      const Color(0xFF1C1C1E).withValues(alpha: 0.72),
    );
    expect(
      gradient.colors.first,
      Color.lerp(
        const Color(0xFF1C1C1E),
        Colors.white,
        0.32,
      )!
          .withValues(alpha: 0.18),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('custom Android tint remains visible in the glass gradient', (
    tester,
  ) async {
    const purple = Color(0xFF9333EA);
    final settings = LiquidGlassSettings.matteDark.copyWith(
      tintColor: purple,
      tintOpacity: 0.30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassSettingsScope(
          settings: settings,
          child: const LiquidGlassCard(
            key: ValueKey('purple-card'),
            child: SizedBox(width: 120, height: 60),
          ),
        ),
      ),
    );

    final decoration = _glassDecorationUnder(tester, 'purple-card');
    final gradient = decoration.gradient! as LinearGradient;

    expect(decoration.color, purple.withValues(alpha: 0.30));
    expect(
      gradient.colors.first,
      Color.lerp(purple, Colors.white, 0.32)!.withValues(alpha: 0.18),
    );
    expect(gradient.colors.last, purple.withValues(alpha: 0.10));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('high contrast strengthens fallback tint and border', (
    tester,
  ) async {
    const tint = Color(0xFF2563EB);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(highContrast: true),
          child: LiquidGlassCard(
            key: ValueKey('high-contrast-card'),
            settings: LiquidGlassSettings(
              tintColor: tint,
              tintOpacity: 0.2,
              borderOpacity: 0.1,
            ),
            child: SizedBox(width: 120, height: 60),
          ),
        ),
      ),
    );

    final decoration = _glassDecorationUnder(tester, 'high-contrast-card');
    expect(decoration.color, tint.withValues(alpha: 0.78));
    expect(
      decoration.border,
      Border.all(
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Android nav bar can render a custom widget icon', (
    tester,
  ) async {
    const items = [
      LiquidGlassNavItem(
        icon: Icons.home,
        label: 'Home',
        androidIcon: Text('H'),
      ),
      LiquidGlassNavItem(
        icon: Icons.search,
        label: 'Search',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              LiquidGlassNavBar(
                currentIndex: 0,
                onTap: _noop,
                items: items,
                scrollConfiguration:
                    const LiquidGlassNavBarScrollConfiguration(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('H'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'Android nav bar collapses down and expands up or after idle',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ListView(
                  key: const ValueKey('scroll-list'),
                  children: const [SizedBox(height: 1200)],
                ),
                LiquidGlassNavBar(
                  currentIndex: 0,
                  onTap: _noop,
                  items: _navItems,
                  scrollConfiguration:
                      const LiquidGlassNavBarScrollConfiguration(
                    collapsedScale: 0.7,
                    collapseThreshold: 1,
                    animationDuration: Duration.zero,
                    idleExpandDuration: Duration(seconds: 5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final scaleFinder =
          find.byKey(const ValueKey('liquid-glass-nav-dock-scale'));
      double scale() => tester.widget<AnimatedScale>(scaleFinder).scale;

      expect(scale(), 1);

      final downwardScroll = await tester.startGesture(const Offset(200, 200));
      await downwardScroll.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(scale(), 0.7);

      await downwardScroll.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(scale(), 1);
      await downwardScroll.up();

      final idleScroll = await tester.startGesture(const Offset(200, 200));
      await idleScroll.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(scale(), 0.7);
      await idleScroll.up();
      await tester.pump(const Duration(seconds: 5));
      expect(scale(), 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('Android nav indicator grows beyond the bar during a jump', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Stack(
              children: [
                LiquidGlassNavBar(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  items: _navItems,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Saved'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 275));

    final indicator = tester.getRect(
      find.byKey(const ValueKey('liquid-glass-nav-indicator')),
    );
    expect(indicator.height, greaterThan(64));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Android nav indicator follows a held horizontal drag', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Stack(
              children: [
                LiquidGlassNavBar(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  items: _navItems,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final navRect = tester.getRect(find.byType(LiquidGlassNavBar));
    final itemWidth = navRect.width / _navItems.length;
    final gesture = await tester.startGesture(
      Offset(navRect.left + itemWidth / 2, navRect.center.dy),
    );
    await gesture.moveTo(
      Offset(navRect.right - itemWidth / 2, navRect.center.dy),
    );
    await tester.pump();

    final indicator = tester.getRect(
      find.byKey(const ValueKey('liquid-glass-nav-indicator')),
    );
    expect(indicator.center.dx, closeTo(navRect.right - itemWidth / 2, 1));

    final savedLabel = tester.widget<AnimatedDefaultTextStyle>(
      _animatedLabel('Saved'),
    );
    expect(savedLabel.style.color, Colors.white);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(selectedIndex, 0);

    await gesture.up();
    await tester.pump();
    expect(selectedIndex, 2);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('holding the Android nav indicator expands it', (tester) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Stack(
              children: [
                LiquidGlassNavBar(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  items: _navItems,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final indicatorFinder =
        find.byKey(const ValueKey('liquid-glass-nav-indicator'));
    final restingRect = tester.getRect(indicatorFinder);
    final gesture = await tester.startGesture(restingRect.center);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 180));

    final heldRect = tester.getRect(indicatorFinder);
    expect(heldRect.width, greaterThan(restingRect.width));
    expect(heldRect.height, greaterThan(restingRect.height));
    expect(selectedIndex, 0);

    await gesture.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('cancelling an Android nav drag restores the current item', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Stack(
              children: [
                LiquidGlassNavBar(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  items: _navItems,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final navRect = tester.getRect(find.byType(LiquidGlassNavBar));
    final itemWidth = navRect.width / _navItems.length;
    final gesture = await tester.startGesture(
      Offset(navRect.left + itemWidth / 2, navRect.center.dy),
    );
    await gesture.moveTo(
      Offset(navRect.right - itemWidth / 2, navRect.center.dy),
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    final homeLabel = tester.widget<AnimatedDefaultTextStyle>(
      _animatedLabel('Home'),
    );
    expect(homeLabel.style.color, Colors.white);
    expect(selectedIndex, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}

void _noop(int index) {}

void _noopVoid() {}

const _navItems = [
  LiquidGlassNavItem(icon: Icons.home, label: 'Home'),
  LiquidGlassNavItem(icon: Icons.search, label: 'Search'),
  LiquidGlassNavItem(
    icon: Icons.favorite_border,
    activeIcon: Icons.favorite,
    label: 'Saved',
  ),
];

Finder _animatedLabel(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is AnimatedDefaultTextStyle &&
        widget.child is Text &&
        (widget.child as Text).data == label,
  );
}

LiquidGlassSettings _fallbackSettingsUnder(
  WidgetTester tester,
  String key,
) {
  final fallback = tester.widget<FallbackGlass>(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(FallbackGlass),
    ),
  );
  return fallback.settings;
}

BoxDecoration _glassDecorationUnder(WidgetTester tester, String key) {
  return tester
      .widgetList<Container>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Container),
        ),
      )
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .singleWhere((decoration) => decoration.gradient != null);
}
