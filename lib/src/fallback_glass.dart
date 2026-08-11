import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'liquid_glass_settings.dart';

/// Pure-Flutter glassmorphism renderer.
///
/// Used on Android. It renders adaptive matte glass when [tintColor] is null,
/// or coloured glass when the caller provides a tint.
class FallbackGlass extends StatelessWidget {
  const FallbackGlass({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.settings,
    this.useSharedBackdrop = true,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final LiquidGlassSettings settings;

  /// Whether this surface can share one backdrop pass with sibling glass
  /// surfaces inside [LiquidGlassBackdropGroup].
  ///
  /// Keep this disabled for floating surfaces that can overlap scroll content
  /// (for example bottom navigation bars). Overlapping grouped backdrop filters
  /// can visually cancel each other and make the glass look transparent during
  /// Android overscroll.
  final bool useSharedBackdrop;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final androidColor =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? settings.androidColor
            : null;
    if (androidColor != null) {
      return SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: ColoredBox(
            color: androidColor,
            child: child,
          ),
        ),
      );
    }

    final performance = _BackdropPerformanceScope.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final tint = settings.tintColor ??
        (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8FA));
    final surfaceIsDark =
        ThemeData.estimateBrightnessForColor(tint) == Brightness.dark;
    final tintedHighlight = Color.lerp(
      tint,
      Colors.white,
      surfaceIsDark ? 0.32 : 0.18,
    )!;
    final highlight = settings.tintColor == null
        ? Colors.white.withValues(alpha: isDark ? 0.06 : 0.22)
        : tintedHighlight.withValues(alpha: surfaceIsDark ? 0.18 : 0.16);
    final lowlight = settings.tintColor == null
        ? Colors.white.withValues(alpha: surfaceIsDark ? 0.025 : 0.05)
        : tint.withValues(alpha: surfaceIsDark ? 0.10 : 0.08);

    final blurSigma =
        settings.blurSigma.clamp(0.0, settings.androidBlurSigma).toDouble();
    final tintOpacity = highContrast
        ? math.max(settings.tintOpacity, surfaceIsDark ? 0.78 : 0.68)
        : settings.tintOpacity;
    final borderOpacity = highContrast
        ? math.max(settings.borderOpacity, 0.55)
        : settings.borderOpacity;
    final glassContent = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // Tint layer
        color: tint.withValues(alpha: tintOpacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: borderOpacity),
          width: settings.borderWidth,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlight,
            lowlight,
          ],
        ),
      ),
      child: child,
    );
    final filteredContent = blurSigma == 0
        ? glassContent
        : _SharedBackdropFilter(
            sigma: blurSigma,
            enabled: useSharedBackdrop,
            blurDisabled: performance?.blurDisabled ?? false,
            child: glassContent,
          );

    final shadowEnabled =
        !(performance?.shadowsDisabled ?? false) && settings.shadowOpacity > 0;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: shadowEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: settings.shadowOpacity,
                    ),
                    blurRadius: settings.shadowBlurRadius,
                    offset: settings.shadowOffset,
                  ),
                ]
              : const [],
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: filteredContent,
          ),
        ),
      ),
    );
  }
}

/// Shares backdrop input between non-overlapping fallback surfaces.
///
/// Wrap a screen or section containing several non-overlapping Liquid Glass
/// widgets with [LiquidGlassBackdropGroup] to reduce Android blur passes to
/// one.
///
/// Do not wrap multiple [PageView] pages or route transitions in one group:
/// pages can overlap while moving, which can make grouped backdrop filters
/// sample the wrong backdrop and visibly change color during the transition.
///
/// Native iOS surfaces are separate Flutter platform views, so they cannot
/// share one SwiftUI `GlassEffectContainer` or native morphing namespace.
class LiquidGlassBackdropGroup extends StatefulWidget {
  /// Creates a shared backdrop and optional settings boundary around [child].
  ///
  /// Group only non-overlapping glass surfaces. Overlapping filters that share
  /// a backdrop key can sample the wrong input and appear transparent.
  const LiquidGlassBackdropGroup({
    super.key,
    required this.child,
    this.settings,
    this.disableBlurWhileScrolling = true,
    this.disableShadowsWhileScrolling = true,
    this.effectRestoreDelay = const Duration(milliseconds: 80),
  });

  /// Subtree containing the glass surfaces and, commonly, its scrollable.
  final Widget child;

  /// Baseline settings inherited by descendant Liquid Glass components.
  ///
  /// A component that supplies its own `settings` overrides this value.
  final LiquidGlassSettings? settings;

  /// Whether grouped fallback surfaces temporarily use their matte tint only
  /// while a descendant scrollable is moving.
  ///
  /// Disabling backdrop blur during motion substantially reduces Android GPU
  /// work. The blur is restored as soon as scrolling settles.
  final bool disableBlurWhileScrolling;

  /// Whether fallback drop shadows are temporarily removed during scrolling.
  ///
  /// Blurred shadows create an additional GPU filter for every surface.
  final bool disableShadowsWhileScrolling;

  /// Delay after scrolling ends before disabled blur and shadows are restored.
  ///
  /// A short delay prevents expensive effects from being recreated between
  /// closely spaced drag and ballistic-scroll notifications.
  final Duration effectRestoreDelay;

  @override
  State<LiquidGlassBackdropGroup> createState() =>
      _LiquidGlassBackdropGroupState();
}

class _LiquidGlassBackdropGroupState extends State<LiquidGlassBackdropGroup> {
  final BackdropKey _backdropKey = BackdropKey();
  Timer? _effectRestoreTimer;
  bool _isScrolling = false;

  bool get _hasScrollOptimizations =>
      widget.disableBlurWhileScrolling || widget.disableShadowsWhileScrolling;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_hasScrollOptimizations) return false;
    if (notification is ScrollStartNotification) {
      _effectRestoreTimer?.cancel();
      if (!_isScrolling) setState(() => _isScrolling = true);
    } else if (notification is ScrollEndNotification && _isScrolling) {
      _effectRestoreTimer?.cancel();
      if (widget.effectRestoreDelay == Duration.zero) {
        setState(() => _isScrolling = false);
      } else {
        _effectRestoreTimer = Timer(widget.effectRestoreDelay, () {
          if (mounted && _isScrolling) {
            setState(() => _isScrolling = false);
          }
        });
      }
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant LiquidGlassBackdropGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasScrollOptimizations) {
      _effectRestoreTimer?.cancel();
      _isScrolling = false;
    } else if (oldWidget.effectRestoreDelay != widget.effectRestoreDelay &&
        _effectRestoreTimer?.isActive == true) {
      _effectRestoreTimer?.cancel();
      _isScrolling = false;
    }
  }

  @override
  void dispose() {
    _effectRestoreTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scopedChild = widget.settings == null
        ? widget.child
        : LiquidGlassSettingsScope(
            settings: widget.settings!,
            child: widget.child,
          );
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: BackdropGroup(
        backdropKey: _backdropKey,
        child: _BackdropPerformanceScope(
          blurDisabled: widget.disableBlurWhileScrolling && _isScrolling,
          shadowsDisabled: widget.disableShadowsWhileScrolling && _isScrolling,
          child: scopedChild,
        ),
      ),
    );
  }
}

/// Scroll behavior for Android glass-heavy screens.
///
/// Android's default overscroll glow/stretch can temporarily alter backdrop
/// sampling at the start and end of scrollable content. Use this behavior on
/// screens that contain fallback glass surfaces to keep the glass tint stable.
class LiquidGlassScrollBehavior extends MaterialScrollBehavior {
  /// Creates scroll behavior without Android overscroll glow or stretch.
  const LiquidGlassScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _SharedBackdropFilter extends StatefulWidget {
  const _SharedBackdropFilter({
    required this.sigma,
    required this.enabled,
    required this.blurDisabled,
    required this.child,
  });

  final double sigma;
  final bool enabled;
  final bool blurDisabled;
  final Widget child;

  @override
  State<_SharedBackdropFilter> createState() => _SharedBackdropFilterState();
}

class _SharedBackdropFilterState extends State<_SharedBackdropFilter> {
  late ImageFilter _filter = _createFilter();

  ImageFilter _createFilter() =>
      ImageFilter.blur(sigmaX: widget.sigma, sigmaY: widget.sigma);

  @override
  void didUpdateWidget(covariant _SharedBackdropFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sigma != widget.sigma) _filter = _createFilter();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enabled && BackdropGroup.of(context) != null) {
      return BackdropFilter.grouped(
        filter: _filter,
        enabled: !widget.blurDisabled,
        child: widget.child,
      );
    }
    return BackdropFilter(
      filter: _filter,
      enabled: !widget.blurDisabled,
      child: widget.child,
    );
  }
}

class _BackdropPerformanceScope extends InheritedWidget {
  const _BackdropPerformanceScope({
    required this.blurDisabled,
    required this.shadowsDisabled,
    required super.child,
  });

  final bool blurDisabled;
  final bool shadowsDisabled;

  static _BackdropPerformanceScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_BackdropPerformanceScope>();
  }

  @override
  bool updateShouldNotify(_BackdropPerformanceScope oldWidget) {
    return blurDisabled != oldWidget.blurDisabled ||
        shadowsDisabled != oldWidget.shadowsDisabled;
  }
}
