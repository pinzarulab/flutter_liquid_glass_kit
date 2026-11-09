import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass_settings.dart';
import 'liquid_glass_route_observer.dart';
import 'fallback_glass.dart';
import 'native_glass_group.dart';

/// Whether glass widgets use a native Apple renderer on this platform.
///
/// The native view itself uses the OS availability check for Liquid Glass. On
/// iOS and macOS versions before Liquid Glass is available, it provides a
/// native material fallback. Android, Windows, web, and other platforms return
/// false and use the Flutter fallback.
bool get isNativeLiquidGlassSupported {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}

/// Core widget that routes to a native Apple platform view or the
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
    this.nativeGlassEnabled = true,
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
  /// This flag has no effect on native Apple renderers.
  final bool useSharedBackdrop;

  /// Whether native Apple platforms should apply interactive glass response.
  ///
  /// Cards are passive by default. Buttons and editable controls enable this.
  final bool interactive;

  /// Whether this surface can use an Apple platform view.
  ///
  /// Set to false to force the Flutter renderer while keeping [child] mounted.
  final bool nativeGlassEnabled;

  /// Optional fixed width. When null, normal parent constraints are used.
  final double? width;

  /// Optional fixed height. When null, the child determines the height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveSettings = LiquidGlassSettings.resolve(context, _settings);
    if (isNativeLiquidGlassSupported) {
      return LiquidGlassRouteVisibility(
        builder: (context, visible) {
          final useNative = nativeGlassEnabled && visible;
          final group = LiquidGlassNativeGroupScope.maybeOf(context);
          final Widget background;
          if (!useNative) {
            background = FallbackGlass(
              borderRadius: borderRadius,
              settings: effectiveSettings,
              useSharedBackdrop: useSharedBackdrop,
              child: const SizedBox.expand(),
            );
          } else if (group != null) {
            background = LiquidGlassGroupedSurface(
              controller: group,
              borderRadius: borderRadius,
              settings: effectiveSettings,
              interactive: interactive,
              child: const SizedBox.expand(),
            );
          } else {
            background = _NativeLiquidGlass(
              borderRadius: borderRadius,
              settings: effectiveSettings,
              interactive: interactive,
            );
          }
          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned.fill(child: background),
                ClipRRect(
                  borderRadius: borderRadius,
                  clipBehavior: useNative ? Clip.none : Clip.antiAlias,
                  child: child,
                ),
              ],
            ),
          );
        },
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
// Native Apple implementation via UIKit/AppKit + SwiftUI
// ---------------------------------------------------------------------------

class _NativeLiquidGlass extends StatelessWidget {
  const _NativeLiquidGlass({
    required this.borderRadius,
    required this.settings,
    required this.interactive,
  });

  final BorderRadius borderRadius;
  final LiquidGlassSettings settings;
  final bool interactive;

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
        'borderOpacity': settings.borderOpacity,
        'borderWidth': settings.borderWidth,
        'iosGlassStyle': settings.iosGlassStyle.name,
        'interactive': interactive,
      };

  @override
  Widget build(BuildContext context) {
    return defaultTargetPlatform == TargetPlatform.macOS
        ? AppKitView(
            viewType: 'flutter_liquid_glass_kit/glass_surface',
            creationParams: _creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          )
        : UiKitView(
            key: ValueKey((settings.borderOpacity, settings.borderWidth)),
            viewType: 'flutter_liquid_glass_kit/glass_surface',
            creationParams: _creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          );
  }
}
