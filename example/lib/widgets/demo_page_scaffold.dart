import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';

class DemoPageScaffold extends StatelessWidget {
  const DemoPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.leadingEmoji,
    this.settings,
  });

  final String title;
  final String subtitle;
  final String? leadingEmoji;
  final List<Widget> children;
  final LiquidGlassSettings? settings;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBackdropGroup(
      disableBlurWhileScrolling: false,
      disableShadowsWhileScrolling: false,
      settings: settings ?? const LiquidGlassSettings(androidBlurSigma: 4),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              leadingEmoji == null ? subtitle : '$leadingEmoji  $subtitle',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 40),
            ...children,
          ],
        ),
      ),
    );
  }
}
