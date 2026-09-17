import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass_settings.dart';
import 'fallback_glass.dart';
import 'native_glass_group.dart';

/// Whether glass widgets use the native iOS renderer on this platform.
///
/// The native view itself uses the OS availability check for Liquid Glass. On
/// iOS versions before Liquid Glass is available, it provides a native material
/// fallback. Android, web, and desktop platforms return false and use the
/// Flutter fallback.
bool get isNativeLiquidGlassSupported {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

/// Core widget that routes to the native iOS PlatformView or Android's
/// cross-platform matte-glass renderer.
///
/// You typically don't use this directly — prefer [LiquidGlassCard],
/// [LiquidGlassButton], or [LiquidGlassNavBar].
class PlatformGlass extends StatelessWidget {
  /// Creates the platform-adaptive glass surface used by higher-level widgets.
  ///
  /// When `settings` is omitted, the nearest shared settings scope is used.
  /// Most applications should prefer [LiquidGlassCard], [LiquidGlassButton],
  /// or [LiquidGlassNavBar].
  const PlatformGlass({
    super.key,
    required this.child,
    required this.borderRadius,
    LiquidGlassSettings? settings,
    this.useSharedBackdrop = true,
    this.interactive = false,
    this.width,
    this.height,
  }) : _settings = settings;

  /// Content painted above the native or fallback glass surface.
  final Widget child;

  /// Shape of the surface.
  final BorderRadius borderRadius;
  final LiquidGlassSettings? _settings;

  /// The locally supplied settings, or [LiquidGlassSettings.matteLight] when
  /// no local settings were supplied.
  ///
  /// The effective inherited value is resolved during build.
  LiquidGlassSettings get settings =>
      _settings ?? LiquidGlassSettings.matteLight;

  /// Whether Android fallback surfaces can use [BackdropFilter.grouped].
  ///
  /// Disable this for floating surfaces that may overlap other glass widgets.
  /// This flag has no effect on the native iOS renderer.
  final bool useSharedBackdrop;

  /// Whether native iOS should apply interactive glass response.
  ///
  /// Cards are passive by default. Buttons and editable controls enable this.
  final bool interactive;

  /// Optional fixed width. When null, normal parent constraints are used.
  final double? width;

  /// Optional fixed height. When null, the child determines the height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveSettings = LiquidGlassSettings.resolve(context, _settings);
    if (isNativeLiquidGlassSupported) {
      final group = LiquidGlassNativeGroupScope.maybeOf(context);
      if (group != null) {
        return LiquidGlassGroupedSurface(
          controller: group,
          borderRadius: borderRadius,
          settings: effectiveSettings,
          interactive: interactive,
          width: width,
          height: height,
          child: child,
        );
      }
      return _NativeLiquidGlass(
        borderRadius: borderRadius,
        settings: effectiveSettings,
        interactive: interactive,
        width: width,
        height: height,
        child: child,
      );
    }
    return FallbackGlass(
      borderRadius: borderRadius,
      settings: effectiveSettings,
      useSharedBackdrop: useSharedBackdrop,
      width: width,
      height: height,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Native iOS implementation via UiKitView + SwiftUI
// ---------------------------------------------------------------------------

class _NativeLiquidGlass extends StatelessWidget {
  const _NativeLiquidGlass({
    required this.child,
    required this.borderRadius,
    required this.settings,
    required this.interactive,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final LiquidGlassSettings settings;
  final bool interactive;
  final double? width;
  final double? height;

  Map<String, dynamic> get _creationParams => {
        'topLeftRadius': borderRadius.topLeft.x,
        'topRightRadius': borderRadius.topRight.x,
        'bottomRightRadius': borderRadius.bottomRight.x,
        'bottomLeftRadius': borderRadius.bottomLeft.x,
        'tintColorHex': settings.tintColor != null
            ? '#${settings.tintColor!.toARGB32().toRadixString(16).padLeft(8, '0')}'
            : null,
        'tintOpacity': settings.tintOpacity,
        'blurSigma': settings.blurSigma,
        'iosGlassStyle': settings.iosGlassStyle.name,
        'interactive': interactive,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        // Let the Flutter child determine the height when this widget is used
        // in a vertical scroll view. StackFit.expand would pass an unbounded
        // height to both children, which prevents the child from being laid
        // out. The native view is positioned after the stack has a real size.
        fit: StackFit.passthrough,
        children: [
          // The native SwiftUI glass surface sits behind the Flutter child
          Positioned.fill(
            child: UiKitView(
              viewType: 'flutter_liquid_glass_kit/glass_surface',
              creationParams: _creationParams,
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
          // Flutter child renders on top (hit-testing preserved)
          child,
        ],
      ),
    );
  }
}
