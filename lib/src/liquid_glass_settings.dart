import 'package:flutter/material.dart';

/// Shared visual configuration for all Liquid Glass widgets.
///
/// On iOS, the supported values are forwarded to the native glass surface.
/// On Android, they control the Flutter matte-glass fallback. Set [tintColor]
/// to use a coloured glass surface; leave it null for adaptive matte glass.
/// Set [androidColor] to use a faster solid Android surface with no glass
/// effects.
class LiquidGlassSettings {
  /// Creates an immutable Liquid Glass visual configuration.
  ///
  /// Opacity values are expected to be between `0.0` and `1.0`. On Android,
  /// the effective blur is the lower of [blurSigma] and [androidBlurSigma].
  /// Shadow and border properties affect the Flutter fallback renderer; iOS
  /// native surfaces use the closest available system material treatment.
  const LiquidGlassSettings({
    this.tintColor,
    this.androidColor,
    this.tintOpacity = 0.15,
    this.blurSigma = 20.0,
    this.androidBlurSigma = 8.0,
    this.borderOpacity = 0.25,
    this.borderWidth = 1.0,
    this.shadowOpacity = 0.12,
    this.shadowBlurRadius = 16.0,
    this.shadowOffset = const Offset(0, 4),
  });

  /// Optional colour overlaid on the glass surface.
  ///
  /// On Android this is the colour requested by the caller. If it is omitted,
  /// the fallback selects an adaptive light or dark matte colour.
  final Color? tintColor;

  /// Optional exact color for a solid Android surface.
  ///
  /// When non-null on Android, the renderer skips backdrop blur, tint layers,
  /// gradients, borders, and shadows. This is the lowest-cost rendering mode
  /// for long lists and animation-heavy screens. It has no effect on iOS,
  /// web, or desktop.
  final Color? androidColor;

  /// Opacity of [tintColor], from `0.0` (transparent) to `1.0` (opaque).
  ///
  /// A saturated custom tint commonly looks best between `0.20` and `0.40`.
  final double tintOpacity;

  /// Requested Gaussian blur sigma for content behind the surface.
  ///
  /// This value is forwarded to native iOS surfaces. Android additionally
  /// caps it with [androidBlurSigma] to control GPU cost.
  final double blurSigma;

  /// Maximum blur used by the Android fallback renderer.
  ///
  /// Android backdrop blurs are substantially more expensive than the native
  /// iOS material. The lower default keeps scrolling and selection animations
  /// responsive while retaining the matte-glass appearance. Set to `0` to
  /// disable Android backdrop blur entirely.
  final double androidBlurSigma;

  /// Opacity of the fallback renderer's white border highlight.
  final double borderOpacity;

  /// Width of the fallback renderer's border in logical pixels.
  final double borderWidth;

  /// Opacity of the fallback renderer's black drop shadow.
  final double shadowOpacity;

  /// Blur radius of the fallback renderer's drop shadow.
  final double shadowBlurRadius;

  /// Offset of the fallback renderer's drop shadow.
  final Offset shadowOffset;

  /// A bright neutral preset suited to dark or colorful backgrounds.
  static const LiquidGlassSettings matteLight = LiquidGlassSettings(
    tintColor: Colors.white,
    tintOpacity: 0.18,
    blurSigma: 24,
    borderOpacity: 0.30,
  );

  /// A stronger charcoal preset with a reduced Android blur cap.
  ///
  /// Use this when the surface must remain visibly dark independently of the
  /// surrounding app theme.
  static const LiquidGlassSettings matteDark = LiquidGlassSettings(
    tintColor: Color(0xFF1C1C1E),
    tintOpacity: 0.72,
    blurSigma: 24,
    androidBlurSigma: 8,
    borderOpacity: 0.18,
    shadowOpacity: 0.20,
  );

  /// Resolves the effective settings for a component.
  ///
  /// Resolution order is [localSettings], the nearest
  /// [LiquidGlassSettingsScope], then [matteLight]. Components call this during
  /// build so local settings always override inherited baseline settings.
  static LiquidGlassSettings resolve(
    BuildContext context,
    LiquidGlassSettings? localSettings,
  ) {
    return localSettings ??
        LiquidGlassSettingsScope.maybeOf(context) ??
        matteLight;
  }

  /// Returns a copy with the supplied fields replaced.
  ///
  /// Omitted fields retain their current values. Because `null` means "keep the
  /// current value", this method cannot clear an existing [tintColor] or
  /// [androidColor]. Create a new [LiquidGlassSettings] instance when either
  /// nullable color must be cleared.
  LiquidGlassSettings copyWith({
    Color? tintColor,
    Color? androidColor,
    double? tintOpacity,
    double? blurSigma,
    double? androidBlurSigma,
    double? borderOpacity,
    double? borderWidth,
    double? shadowOpacity,
    double? shadowBlurRadius,
    Offset? shadowOffset,
  }) {
    return LiquidGlassSettings(
      tintColor: tintColor ?? this.tintColor,
      androidColor: androidColor ?? this.androidColor,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      blurSigma: blurSigma ?? this.blurSigma,
      androidBlurSigma: androidBlurSigma ?? this.androidBlurSigma,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      borderWidth: borderWidth ?? this.borderWidth,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LiquidGlassSettings &&
            tintColor == other.tintColor &&
            androidColor == other.androidColor &&
            tintOpacity == other.tintOpacity &&
            blurSigma == other.blurSigma &&
            androidBlurSigma == other.androidBlurSigma &&
            borderOpacity == other.borderOpacity &&
            borderWidth == other.borderWidth &&
            shadowOpacity == other.shadowOpacity &&
            shadowBlurRadius == other.shadowBlurRadius &&
            shadowOffset == other.shadowOffset;
  }

  @override
  int get hashCode => Object.hash(
        tintColor,
        androidColor,
        tintOpacity,
        blurSigma,
        androidBlurSigma,
        borderOpacity,
        borderWidth,
        shadowOpacity,
        shadowBlurRadius,
        shadowOffset,
      );
}

/// Provides baseline settings to descendant Liquid Glass components.
///
/// [LiquidGlassBackdropGroup] creates this scope when its `settings` argument
/// is supplied. This widget is also public for layouts that need shared
/// settings without backdrop grouping.
class LiquidGlassSettingsScope extends InheritedWidget {
  /// Provides [settings] to Liquid Glass descendants that omit local settings.
  const LiquidGlassSettingsScope({
    super.key,
    required this.settings,
    required super.child,
  });

  /// Baseline settings inherited by descendant components.
  final LiquidGlassSettings settings;

  /// Returns the nearest inherited settings, or `null` when no scope exists.
  ///
  /// Calling this method establishes a dependency on the scope, so the caller
  /// rebuilds when [settings] changes.
  static LiquidGlassSettings? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LiquidGlassSettingsScope>()
        ?.settings;
  }

  @override
  bool updateShouldNotify(LiquidGlassSettingsScope oldWidget) {
    return settings != oldWidget.settings;
  }
}
