import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';

import 'pages/profile_page.dart';
import 'pages/saved_page.dart';
import 'pages/search_page.dart';
import 'pages/showcase_page.dart';
import 'widgets/demo_background.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Kit Demo',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const LiquidGlassScrollBehavior(),
      theme: ThemeData.dark(),
      home: const GlassShowcase(),
    );
  }
}

class GlassShowcase extends StatefulWidget {
  const GlassShowcase({super.key});

  @override
  State<GlassShowcase> createState() => _GlassShowcaseState();
}

class _GlassShowcaseState extends State<GlassShowcase> {
  final _pageController = PageController();
  int _navIndex = 0;
  int? _programmaticTargetIndex;
  bool _loading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setNavIndex(int index) async {
    if (index == _navIndex) return;
    setState(() {
      _programmaticTargetIndex = index;
      _navIndex = index;
    });
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(index, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    if (!mounted || _programmaticTargetIndex != index) return;
    setState(() => _programmaticTargetIndex = null);
  }

  void _onPageChanged(int index) {
    if (_programmaticTargetIndex != null) return;
    if (index == _navIndex) return;
    setState(() => _navIndex = index);
  }

  void _runLoadingDemo() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSettingsScope(
      settings: LiquidGlassSettings.matteDark.copyWith(tintColor: const Color(0xFF9333EA), tintOpacity: 0.3),

      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DemoBackground(),
            SafeArea(
              bottom: false,
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  ShowcasePage(loading: _loading, onToggleLoading: _runLoadingDemo),
                  const SearchPage(),
                  const SavedPage(),
                  const ProfilePage(),
                ],
              ),
            ),
            LiquidGlassFloatingNavBar(
              child: LiquidGlassNavBar(
                currentIndex: _navIndex,
                onTap: _setNavIndex,
                scrollConfiguration:
                    const LiquidGlassNavBarScrollConfiguration(),
                androidScrollConfiguration:
                    const LiquidGlassNavBarScrollConfiguration(
                  collapsedScale: 0.85,
                  collapseThreshold: 20,
                  animationDuration: Duration(milliseconds: 500),
                ),
                items: const [
                LiquidGlassNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  iosSystemImage: 'house',
                  iosSelectedSystemImage: 'house.fill',
                ),
                LiquidGlassNavItem(
                  icon: Icons.search,
                  label: 'Search',
                  badge: 3,
                  androidIcon: SizedBox.square(
                    dimension: 25,
                    child: Center(
                      child: Text('S', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  iosSystemImage: 'magnifyingglass',
                ),
                LiquidGlassNavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: 'Saved',
                  iosSystemImage: 'heart',
                  iosSelectedSystemImage: 'heart.fill',
                ),
                LiquidGlassNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  iosSystemImage: 'person',
                  iosSelectedSystemImage: 'person.fill',
                ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
