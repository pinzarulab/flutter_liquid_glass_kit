import 'package:flutter/material.dart';

import 'liquid_glass_settings.dart';
import 'platform_glass.dart';

/// A glass-effect container card.
///
/// On iOS 26+ renders via native SwiftUI `.glassEffect()`.
/// On Android and older iOS uses a blur + tint fallback.
///
/// ```dart
/// LiquidGlassCard(
///   child: Padding(
///     padding: EdgeInsets.all(20),
///     child: Text('Hello, Glass!'),
///   ),
/// )
/// ```
class LiquidGlassCard extends StatelessWidget {
  /// Creates a glass container around [child].
  ///
  /// When `settings` is omitted, the card inherits from the nearest
  /// [LiquidGlassSettingsScope] or [LiquidGlassBackdropGroup], then falls back
  /// to [LiquidGlassSettings.matteLight].
  const LiquidGlassCard({
    super.key,
    required this.child,
    LiquidGlassSettings? settings,
    this.androidColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  }) : _settings = settings;

  /// Content painted above the glass surface.
  final Widget child;
  final LiquidGlassSettings? _settings;

  /// Optional solid Android color for this card.
  ///
  /// This overrides inherited [LiquidGlassSettings.androidColor] and disables
  /// Android glass effects for this card. It has no effect on other platforms.
  final Color? androidColor;

  /// The locally supplied settings, or [LiquidGlassSettings.matteLight] when
  /// no local settings were supplied.
  ///
  /// This getter cannot include inherited settings because it has no
  /// [BuildContext]. The effective value is resolved during build.
  LiquidGlassSettings get settings =>
      _settings ?? LiquidGlassSettings.matteLight;

  /// Shape of the glass surface and its clipping boundary.
  final BorderRadius borderRadius;

  /// Optional fixed width. When null, normal parent constraints are used.
  final double? width;

  /// Optional fixed height. When null, the child determines the height.
  final double? height;

  /// Inner padding applied to [child].
  final EdgeInsetsGeometry padding;

  /// Outer margin around the card.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    var effectiveSettings = LiquidGlassSettings.resolve(context, _settings);
    if (androidColor != null) {
      effectiveSettings = effectiveSettings.copyWith(
        androidColor: androidColor,
      );
    }
    return Padding(
      padding: margin,
      child: PlatformGlass(
        borderRadius: borderRadius,
        settings: effectiveSettings,
        width: width,
        height: height,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
