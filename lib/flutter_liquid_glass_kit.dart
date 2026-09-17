/// Platform-adaptive Liquid Glass components for Flutter.
///
/// The package renders native SwiftUI glass on iOS and an optimized Flutter
/// matte-glass fallback on Android, web, and desktop. Start with
/// [LiquidGlassCard], [LiquidGlassButton], [LiquidGlassTextField], or
/// [LiquidGlassNavBar]. Use [LiquidGlassFloatingNavBar] when navigation should
/// float above content. Use
/// [LiquidGlassSettingsScope] for an app-wide baseline and
/// [LiquidGlassBackdropGroup] around each page of non-overlapping glass
/// surfaces. This shares one native host on iOS and can coordinate backdrop
/// work on Android. Set [LiquidGlassSettings.androidColor] for a low-cost solid
/// Android surface with no glass effects.
library flutter_liquid_glass_kit;

export 'src/liquid_glass_card.dart';
export 'src/liquid_glass_button.dart';
export 'src/liquid_glass_nav_bar.dart';
export 'src/liquid_glass_settings.dart';
export 'src/liquid_glass_text_field.dart';
export 'src/platform_glass.dart';
export 'src/fallback_glass.dart'
    show LiquidGlassBackdropGroup, LiquidGlassScrollBehavior;
