import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';

import '../widgets/demo_page_scaffold.dart';
import '../widgets/section_label.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPageScaffold(
      title: 'Saved Surfaces',
      leadingEmoji: '💜',
      subtitle: 'A different layout for testing nav transitions',
      settings: const LiquidGlassSettings(androidColor: Color(0xFF355C68)),
      children: [
        const SectionLabel('Pinned Components'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            SavedTile(icon: Icons.credit_card, title: 'Glass Card'),
            SavedTile(icon: Icons.touch_app, title: 'Button'),
            SavedTile(icon: Icons.tab, title: 'Nav Bar'),
            SavedTile(icon: Icons.palette_outlined, title: 'Tint'),
          ],
        ),
        const SizedBox(height: 24),
        LiquidGlassCard(
          settings: const LiquidGlassSettings(
            tintColor: Color(0xFF9333EA),
            tintOpacity: 0.30,
            androidColor: Color(0xFF694A83),
          ),
          child: const Text(
            'Saved page uses a grid and tinted summary card so route changes are '
            'obvious when testing nav motion.',
            style: TextStyle(color: Color(0xDDFFFFFF), height: 1.5),
          ),
        ),
      ],
    );
  }
}

class SavedTile extends StatelessWidget {
  const SavedTile({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
