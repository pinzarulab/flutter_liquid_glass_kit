import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass_settings.dart';
import 'platform_glass.dart';

/// Built-in motion styles for the Android navigation indicator.
enum LiquidGlassNavBarAnimationStyle {
  /// Liquid vertical stretching based on travel distance and drag speed.
  liquid,

  /// A wider, spring-like blob with a pronounced velocity response.
  elastic,

  /// A balanced width-and-height pulse around the selected item.
  pulse,

  /// Restrained movement with minimal shape distortion.
  smooth,
}

/// Resolves the Android navigation indicator geometry for one animation frame.
///
/// Return a rectangle in the navigation bar's local coordinate system. The
/// callback must be fast and free of side effects because it runs every frame.
typedef LiquidGlassNavBarAnimationResolver = Rect Function(
  LiquidGlassNavBarAnimationState state,
);

/// Inputs available to a custom Android navigation indicator animation.
@immutable
class LiquidGlassNavBarAnimationState {
  /// Creates an immutable indicator animation snapshot.
  const LiquidGlassNavBarAnimationState({
    required this.restingRect,
    required this.center,
    required this.fromCenter,
    required this.toCenter,
    required this.itemWidth,
    required this.dockHeight,
    required this.transitionProgress,
    required this.holdProgress,
    required this.dragVelocity,
    required this.isDragging,
  });

  /// Resting indicator rectangle at [center].
  final Rect restingRect;

  /// Default eased horizontal center for this frame.
  final double center;

  /// Horizontal center at the start of a programmatic transition.
  final double fromCenter;

  /// Horizontal center at the end of a programmatic transition.
  final double toCenter;

  /// Width allocated to one navigation item.
  final double itemWidth;

  /// Height of the navigation bar.
  final double dockHeight;

  /// Raw transition progress from `0.0` to `1.0`.
  final double transitionProgress;

  /// Hold expansion progress from `0.0` to `1.0`.
  final double holdProgress;

  /// Signed horizontal drag velocity in logical pixels per second.
  ///
  /// Positive values move right and negative values move left.
  final double dragVelocity;

  /// Whether the user is currently dragging or holding the indicator.
  final bool isDragging;

  /// Absolute horizontal travel distance for a programmatic transition.
  double get travelDistance => (toCenter - fromCenter).abs();

  /// Absolute drag speed in logical pixels per second.
  double get dragSpeed => dragVelocity.abs();
}

/// A platform-adaptive glass bottom navigation bar.
///
/// This is a normal layout widget, suitable for `Scaffold.bottomNavigationBar`
/// and custom shells. Use [LiquidGlassFloatingNavBar] to position it above
/// content in a [Stack].
///
/// ```dart
/// Scaffold(
///   bottomNavigationBar: SafeArea(
///     minimum: EdgeInsets.all(16),
///     child: LiquidGlassNavBar(
///       currentIndex: _index,
///       onTap: (i) => setState(() => _index = i),
///       items: [
///         LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
///         LiquidGlassNavItem(icon: Icon(Icons.search), label: 'Search'),
///       ],
///     ),
///   ),
/// )
/// ```
class LiquidGlassNavBar extends StatelessWidget {
  /// Creates a controlled navigation bar surface.
  ///
  /// The selected item is controlled by [currentIndex]; [onTap] must update
  /// that value in the parent. On the Flutter fallback, users can hold and drag
  /// the indicator to preview items before releasing.
  ///
  /// When `settings` is omitted, the nearest shared settings scope is used.
  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    LiquidGlassSettings? settings,
    this.height = 64,
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x99FFFFFF),
    this.indicatorColor = const Color(0x33FFFFFF),
    this.showLabels = true,
    this.androidAnimationStyle = LiquidGlassNavBarAnimationStyle.liquid,
    this.androidAnimationResolver,
    this.scrollConfiguration,
    this.iosScrollConfiguration,
    this.androidScrollConfiguration,
  })  : _settings = settings,
        assert(items.length > 1, 'A navigation bar needs at least two items.'),
        assert(currentIndex >= 0 && currentIndex < items.length),
        assert(height > 0);

  /// Items displayed from left to right.
  ///
  /// At least two items are required.
  final List<LiquidGlassNavItem> items;

  /// Index of the currently selected item.
  final int currentIndex;

  /// Called with the selected index after a tap or completed drag.
  ///
  /// Cancelling a drag does not call this callback.
  final ValueChanged<int> onTap;
  final LiquidGlassSettings? _settings;

  /// The locally supplied settings, or [LiquidGlassSettings.matteLight] when
  /// no local settings were supplied.
  ///
  /// The effective inherited value is resolved during build.
  LiquidGlassSettings get settings =>
      _settings ?? LiquidGlassSettings.matteLight;

  /// Height of the navigation surface in logical pixels.
  final double height;

  /// Shape of the fallback navigation surface.
  final BorderRadius borderRadius;

  /// Color inherited by the selected icon, widget, and label.
  final Color activeColor;

  /// Color inherited by unselected icons, widgets, and labels.
  final Color inactiveColor;

  /// Base color used for the animated fallback selection indicator.
  final Color indicatorColor;

  /// Whether labels are displayed below icons on both renderers.
  final bool showLabels;

  /// Built-in Android indicator animation.
  ///
  /// Ignored when [androidAnimationResolver] is supplied.
  final LiquidGlassNavBarAnimationStyle androidAnimationStyle;

  /// Optional custom Android indicator geometry resolver.
  ///
  /// This callback takes precedence over [androidAnimationStyle]. It is ignored
  /// by the native iOS renderer.
  final LiquidGlassNavBarAnimationResolver? androidAnimationResolver;

  /// Scroll-driven resizing shared by native iOS and Android.
  ///
  /// Platform overrides take precedence when supplied. When all three
  /// configuration values are null, scroll-driven resizing is disabled.
  final LiquidGlassNavBarScrollConfiguration? scrollConfiguration;

  /// Optional native iOS override for [scrollConfiguration].
  final LiquidGlassNavBarScrollConfiguration? iosScrollConfiguration;

  /// Optional Android override for [scrollConfiguration].
  final LiquidGlassNavBarScrollConfiguration? androidScrollConfiguration;

  @override
  Widget build(BuildContext context) {
    final effectiveSettings = LiquidGlassSettings.resolve(context, _settings);
    final isNativeIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (isNativeIOS) {
      return _NativeIOSNavBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
        height: height,
        settings: effectiveSettings,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        indicatorColor: indicatorColor,
        showLabels: showLabels,
        scrollConfiguration: iosScrollConfiguration ?? scrollConfiguration,
      );
    }
    return _LiquidGlassDock(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
      height: height,
      settings: effectiveSettings,
      borderRadius: borderRadius,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      indicatorColor: indicatorColor,
      showLabels: showLabels,
      animationStyle: androidAnimationStyle,
      animationResolver: androidAnimationResolver,
      scrollConfiguration:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? androidScrollConfiguration ?? scrollConfiguration
              : null,
    );
  }
}

/// Positions a [LiquidGlassNavBar] above content in a [Stack].
///
/// The wrapper owns horizontal insets and safe-area-aware bottom placement,
/// while the child remains reusable in normal layouts.
class LiquidGlassFloatingNavBar extends StatelessWidget {
  /// Creates a floating placement wrapper for [child].
  const LiquidGlassFloatingNavBar({
    super.key,
    required this.child,
    this.horizontalPadding = 20,
    this.bottomPadding = 16,
    this.iosBottomPadding = 0,
    this.respectSafeArea = true,
  })  : assert(horizontalPadding >= 0),
        assert(bottomPadding >= 0),
        assert(iosBottomPadding >= 0);

  /// Navigation bar surface to position.
  final LiquidGlassNavBar child;

  /// Horizontal inset from the containing [Stack].
  final double horizontalPadding;

  /// Spacing above the safe area on Android and other fallback platforms.
  final double bottomPadding;

  /// Spacing above the safe area on native iOS.
  ///
  /// iOS defaults to zero because its home-indicator safe area is already tall.
  final double iosBottomPadding;

  /// Whether to include the device's bottom safe-area inset.
  final bool respectSafeArea;

  @override
  Widget build(BuildContext context) {
    final isNativeIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final safeBottom =
        respectSafeArea ? MediaQuery.paddingOf(context).bottom : 0.0;
    return Positioned(
      left: horizontalPadding,
      right: horizontalPadding,
      bottom: safeBottom + (isNativeIOS ? iosBottomPadding : bottomPadding),
      child: child,
    );
  }
}

class _NativeIOSNavBar extends StatefulWidget {
  const _NativeIOSNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.height,
    required this.settings,
    required this.activeColor,
    required this.inactiveColor,
    required this.indicatorColor,
    required this.showLabels,
    required this.scrollConfiguration,
  });

  final List<LiquidGlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;
  final LiquidGlassSettings settings;
  final Color activeColor;
  final Color inactiveColor;
  final Color indicatorColor;
  final bool showLabels;
  final LiquidGlassNavBarScrollConfiguration? scrollConfiguration;

  @override
  State<_NativeIOSNavBar> createState() => _NativeIOSNavBarState();
}

class _NativeIOSNavBarState extends State<_NativeIOSNavBar> {
  MethodChannel? _channel;
  late final _NavBarScrollBehavior _scrollBehavior;

  Map<String, dynamic> get _creationParams => {
        'items': [
          for (final item in widget.items)
            {
              'label': item.label,
              'badge': item.badge,
              'iosSystemImage': item.iosSystemImage,
              'iosSelectedSystemImage': item.iosSelectedSystemImage,
            },
        ],
        'currentIndex': widget.currentIndex,
        'tintColorHex': _hex(widget.settings.tintColor ?? Colors.black),
        'tintOpacity': widget.settings.tintOpacity,
        'activeColorHex': _hex(widget.activeColor),
        'inactiveColorHex': _hex(widget.inactiveColor),
        'indicatorColorHex': _hex(widget.indicatorColor),
        'showLabels': widget.showLabels,
        'scrollCollapseScale': widget.scrollConfiguration?.collapsedScale,
        'scrollAnimationDurationMillis':
            widget.scrollConfiguration?.animationDuration.inMilliseconds,
      };

  @override
  void initState() {
    super.initState();
    _scrollBehavior = _NavBarScrollBehavior(
      onCollapsedChanged: (_) => _sendCollapsedState(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollBehavior.update(context, widget.scrollConfiguration);
  }

  @override
  void didUpdateWidget(covariant _NativeIOSNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _channel?.invokeMethod<void>('setCurrentIndex', widget.currentIndex);
      _scrollBehavior.expand();
    }
    if (oldWidget.scrollConfiguration != widget.scrollConfiguration) {
      _scrollBehavior.update(context, widget.scrollConfiguration);
      _sendCollapsedState();
    }
  }

  void _sendCollapsedState() {
    final configuration = widget.scrollConfiguration;
    _channel?.invokeMethod<void>('setCollapsed', {
      'collapsed': _scrollBehavior.isCollapsed && configuration != null,
      'scale': configuration?.collapsedScale ?? 1.0,
      'durationMillis': configuration?.animationDuration.inMilliseconds ?? 0,
    });
  }

  @override
  void dispose() {
    _scrollBehavior.dispose();
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: UiKitView(
        viewType: 'flutter_liquid_glass_kit/native_nav_bar',
        creationParams: _creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          final channel =
              MethodChannel('flutter_liquid_glass_kit/native_nav_bar_$id');
          channel.setMethodCallHandler((call) async {
            if (call.method == 'tap') {
              final index = call.arguments as int;
              _scrollBehavior.expand();
              HapticFeedback.selectionClick();
              widget.onTap(index);
            }
          });
          _channel = channel;
          _sendCollapsedState();
        },
      ),
    );
  }

  String _hex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
  }
}

/// Configures navigation-bar resizing in response to vertical scrolling.
///
/// Pass an instance to [LiquidGlassNavBar.scrollConfiguration] to share the
/// behavior across iOS and Android. Platform-specific overrides remain
/// available when the two renderers need different values.
@immutable
class LiquidGlassNavBarScrollConfiguration {
  /// Creates a scroll-resize configuration.
  const LiquidGlassNavBarScrollConfiguration({
    this.collapsedScale = 0.82,
    this.collapseThreshold = 12,
    this.expandThreshold = 12,
    this.animationDuration = const Duration(milliseconds: 280),
    this.idleExpandDuration = const Duration(seconds: 5),
  })  : assert(collapsedScale > 0 && collapsedScale <= 1),
        assert(collapseThreshold >= 0),
        assert(expandThreshold >= 0);

  /// Scale applied to both width and height while collapsed.
  final double collapsedScale;

  /// Accumulated downward scroll distance required before collapsing.
  final double collapseThreshold;

  /// Accumulated upward scroll distance required before expanding.
  ///
  /// This filters out tiny direction changes while a downward gesture settles.
  final double expandThreshold;

  /// Duration of the resize animation.
  final Duration animationDuration;

  /// Time since the last downward update before automatically expanding.
  final Duration idleExpandDuration;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LiquidGlassNavBarScrollConfiguration &&
            collapsedScale == other.collapsedScale &&
            collapseThreshold == other.collapseThreshold &&
            expandThreshold == other.expandThreshold &&
            animationDuration == other.animationDuration &&
            idleExpandDuration == other.idleExpandDuration;
  }

  @override
  int get hashCode => Object.hash(
        collapsedScale,
        collapseThreshold,
        expandThreshold,
        animationDuration,
        idleExpandDuration,
      );
}

/// Deprecated iOS name for [LiquidGlassNavBarScrollConfiguration].
@Deprecated('Use LiquidGlassNavBarScrollConfiguration.')
typedef LiquidGlassIOSNavBarScrollConfiguration
    = LiquidGlassNavBarScrollConfiguration;

/// Deprecated Android name for [LiquidGlassNavBarScrollConfiguration].
@Deprecated('Use LiquidGlassNavBarScrollConfiguration.')
typedef LiquidGlassAndroidNavBarScrollConfiguration
    = LiquidGlassNavBarScrollConfiguration;

class _NavBarScrollBehavior {
  _NavBarScrollBehavior({required this.onCollapsedChanged});

  final ValueChanged<bool> onCollapsedChanged;
  ScrollNotificationObserverState? _observer;
  Timer? _idleExpandTimer;
  LiquidGlassNavBarScrollConfiguration? _configuration;
  double _accumulatedDownwardScroll = 0;
  double _accumulatedUpwardScroll = 0;

  bool isCollapsed = false;

  void update(
    BuildContext context,
    LiquidGlassNavBarScrollConfiguration? configuration,
  ) {
    _configuration = configuration;
    final nextObserver = configuration == null
        ? null
        : ScrollNotificationObserver.maybeOf(context);
    if (!identical(_observer, nextObserver)) {
      _observer?.removeListener(_handleScrollNotification);
      _observer = nextObserver;
      _observer?.addListener(_handleScrollNotification);
    }
    if (configuration == null) expand();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    final configuration = _configuration;
    if (configuration == null || notification.metrics.axis != Axis.vertical) {
      return;
    }
    if (notification is! ScrollUpdateNotification) return;

    final metrics = notification.metrics;
    final delta = notification.scrollDelta ?? 0;
    if (metrics.pixels <= metrics.minScrollExtent) {
      expand();
      return;
    }
    if (delta < 0) {
      _accumulatedDownwardScroll = 0;
      _accumulatedUpwardScroll += -delta;
      if (_accumulatedUpwardScroll >= configuration.expandThreshold) {
        expand();
      }
      return;
    }
    if (delta == 0) return;

    _accumulatedUpwardScroll = 0;
    _accumulatedDownwardScroll += delta;
    if (_accumulatedDownwardScroll >= configuration.collapseThreshold) {
      _setCollapsed(true);
    }
    _idleExpandTimer?.cancel();
    _idleExpandTimer = Timer(configuration.idleExpandDuration, expand);
  }

  void expand() {
    _idleExpandTimer?.cancel();
    _idleExpandTimer = null;
    _accumulatedDownwardScroll = 0;
    _accumulatedUpwardScroll = 0;
    _setCollapsed(false);
  }

  void _setCollapsed(bool collapsed) {
    if (isCollapsed == collapsed) return;
    isCollapsed = collapsed;
    onCollapsedChanged(collapsed);
  }

  void dispose() {
    _idleExpandTimer?.cancel();
    _observer?.removeListener(_handleScrollNotification);
  }
}

/// Shared floating dock. [PlatformGlass] supplies native Liquid Glass on iOS
/// and the matte/tinted renderer on Android; the selection motion stays the
/// same on both platforms.
class _LiquidGlassDock extends StatefulWidget {
  const _LiquidGlassDock({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.height,
    required this.settings,
    required this.borderRadius,
    required this.activeColor,
    required this.inactiveColor,
    required this.indicatorColor,
    required this.showLabels,
    required this.animationStyle,
    required this.animationResolver,
    required this.scrollConfiguration,
  });

  final List<LiquidGlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;
  final LiquidGlassSettings settings;
  final BorderRadius borderRadius;
  final Color activeColor;
  final Color inactiveColor;
  final Color indicatorColor;
  final bool showLabels;
  final LiquidGlassNavBarAnimationStyle animationStyle;
  final LiquidGlassNavBarAnimationResolver? animationResolver;
  final LiquidGlassNavBarScrollConfiguration? scrollConfiguration;

  @override
  State<_LiquidGlassDock> createState() => _LiquidGlassDockState();
}

class _LiquidGlassDockState extends State<_LiquidGlassDock>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _holdController;
  late final AnimationController _velocityController;
  late final Listenable _indicatorAnimation;
  late final ValueNotifier<double?> _dragCenter;
  late final ValueNotifier<int?> _dragIndex;
  late double _fromPosition;
  late double _toPosition;
  Duration? _lastDragTimestamp;
  double? _lastDragCenter;
  double _dragVelocity = 0;
  late final _NavBarScrollBehavior _scrollBehavior;

  static const _duration = Duration(milliseconds: 550);
  static const _holdDuration = Duration(milliseconds: 180);
  static const _velocityDecayDuration = Duration(milliseconds: 160);
  static const double _holdWidthExpansion = 16;
  static const double _holdHeightExpansion = 14;
  // Long jumps briefly lift the indicator beyond the dock, like the native
  // Liquid Glass selection motion.
  static const double _maxVerticalStretch = 18;

  @override
  void initState() {
    super.initState();
    _fromPosition = widget.currentIndex.toDouble();
    _toPosition = widget.currentIndex.toDouble();
    _dragCenter = ValueNotifier(null);
    _dragIndex = ValueNotifier(null);
    _controller = AnimationController(vsync: this, duration: _duration)
      ..value = 1;
    _holdController = AnimationController(
      vsync: this,
      duration: _holdDuration,
      reverseDuration: const Duration(milliseconds: 140),
    );
    _velocityController = AnimationController(
      vsync: this,
      duration: _velocityDecayDuration,
    )..value = 1;
    _indicatorAnimation = Listenable.merge([
      _controller,
      _holdController,
      _velocityController,
      _dragCenter,
    ]);
    _scrollBehavior = _NavBarScrollBehavior(
      onCollapsedChanged: (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollBehavior.update(context, widget.scrollConfiguration);
  }

  @override
  void didUpdateWidget(covariant _LiquidGlassDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollBehavior.expand();
      _fromPosition = _currentBlobPosition();
      _toPosition = widget.currentIndex.toDouble();
      _controller
        ..stop()
        ..value = 0
        ..forward();
    }
    if (oldWidget.scrollConfiguration != widget.scrollConfiguration) {
      _scrollBehavior.update(context, widget.scrollConfiguration);
    }
  }

  // If a tap interrupts an in-flight animation, start the new leg from
  // wherever the blob visually is right now instead of snapping back.
  double _currentBlobPosition() {
    if (!_controller.isAnimating) return _toPosition;
    final t = widget.animationResolver == null
        ? _positionProgress(widget.animationStyle, _controller.value)
        : Curves.easeOutCubic.transform(_controller.value);
    return _lerp(_fromPosition, _toPosition, t);
  }

  double _clampDragCenter(
    double center,
    double itemWidth,
    double dockWidth,
  ) {
    return center.clamp(itemWidth / 2, dockWidth - itemWidth / 2);
  }

  int _indexForCenter(double center, double itemWidth) {
    return (center / itemWidth).floor().clamp(0, widget.items.length - 1);
  }

  void _startDrag(
    double center,
    double itemWidth,
    double dockWidth, {
    Duration? sourceTimeStamp,
  }) {
    _controller.stop();
    _holdController.forward();
    final clamped = _clampDragCenter(center, itemWidth, dockWidth);
    _lastDragCenter = clamped;
    _lastDragTimestamp = sourceTimeStamp;
    _dragVelocity = 0;
    _velocityController.value = 1;
    _dragIndex.value = _indexForCenter(clamped, itemWidth);
    _dragCenter.value = clamped;
  }

  void _updateDrag(
    double center,
    double itemWidth,
    double dockWidth, {
    Duration? sourceTimeStamp,
  }) {
    final clamped = _clampDragCenter(center, itemWidth, dockWidth);
    final previousCenter = _lastDragCenter;
    if (previousCenter != null) {
      final elapsed = sourceTimeStamp != null && _lastDragTimestamp != null
          ? sourceTimeStamp - _lastDragTimestamp!
          : null;
      final seconds = elapsed != null && elapsed > Duration.zero
          ? elapsed.inMicroseconds / Duration.microsecondsPerSecond
          : 1 / 60;
      final instantaneousVelocity =
          ((clamped - previousCenter) / seconds).clamp(-2400.0, 2400.0);
      _dragVelocity = _lerp(_dragVelocity, instantaneousVelocity, 0.55);
      _velocityController
        ..stop()
        ..value = 0
        ..forward();
    }
    _lastDragCenter = clamped;
    _lastDragTimestamp = sourceTimeStamp;
    final index = _indexForCenter(clamped, itemWidth);
    if (index != _dragIndex.value) {
      HapticFeedback.selectionClick();
      _dragIndex.value = index;
    }
    _dragCenter.value = clamped;
  }

  void _finishDrag(double itemWidth, {required bool selectItem}) {
    final center = _dragCenter.value;
    if (center == null) return;

    final target =
        selectItem ? _indexForCenter(center, itemWidth) : widget.currentIndex;
    _fromPosition = center / itemWidth - 0.5;
    _toPosition = target.toDouble();
    _dragIndex.value = null;
    _dragCenter.value = null;
    _lastDragCenter = null;
    _lastDragTimestamp = null;
    _dragVelocity = 0;
    _velocityController
      ..stop()
      ..value = 1;
    _holdController.reverse();
    _controller
      ..value = 0
      ..forward();

    if (selectItem) {
      _scrollBehavior.expand();
    }
    if (selectItem && target != widget.currentIndex) {
      widget.onTap(target);
    }
  }

  @override
  void dispose() {
    _scrollBehavior.dispose();
    _controller.dispose();
    _holdController.dispose();
    _velocityController.dispose();
    _dragCenter.dispose();
    _dragIndex.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Rect _blobRect(double itemWidth, double dockHeight) {
    final dragCenter = _dragCenter.value;
    final t = _controller.value;
    final fromCenter = (_fromPosition + 0.5) * itemWidth;
    final toCenter = (_toPosition + 0.5) * itemWidth;
    final positionT = widget.animationResolver == null
        ? _positionProgress(widget.animationStyle, t)
        : Curves.easeOutCubic.transform(t);
    final center = dragCenter ?? _lerp(fromCenter, toCenter, positionT);
    final restWidth = itemWidth - 8;
    final restHeight = dockHeight - 8;
    final restingRect = Rect.fromCenter(
      center: Offset(center, dockHeight / 2),
      width: restWidth,
      height: restHeight,
    );
    final velocityDecay =
        1 - Curves.easeOutCubic.transform(_velocityController.value);
    final state = LiquidGlassNavBarAnimationState(
      restingRect: restingRect,
      center: center,
      fromCenter: dragCenter ?? fromCenter,
      toCenter: dragCenter ?? toCenter,
      itemWidth: itemWidth,
      dockHeight: dockHeight,
      transitionProgress: dragCenter == null ? t : 1,
      holdProgress: _holdController.value,
      dragVelocity: dragCenter == null ? 0 : _dragVelocity * velocityDecay,
      isDragging: dragCenter != null,
    );
    return widget.animationResolver?.call(state) ??
        _presetBlobRect(widget.animationStyle, state);
  }

  double _positionProgress(
    LiquidGlassNavBarAnimationStyle style,
    double progress,
  ) {
    return switch (style) {
      LiquidGlassNavBarAnimationStyle.liquid =>
        Curves.easeOutCubic.transform(progress),
      LiquidGlassNavBarAnimationStyle.elastic =>
        Curves.easeOutBack.transform(progress),
      LiquidGlassNavBarAnimationStyle.pulse =>
        Curves.easeInOutCubic.transform(progress),
      LiquidGlassNavBarAnimationStyle.smooth =>
        Curves.easeInOut.transform(progress),
    };
  }

  Rect _presetBlobRect(
    LiquidGlassNavBarAnimationStyle style,
    LiquidGlassNavBarAnimationState state,
  ) {
    final transitionPulse =
        state.isDragging ? 0.0 : math.sin(math.pi * state.transitionProgress);
    final travelFactor =
        (state.travelDistance / (state.itemWidth * 1.5)).clamp(0.65, 1.0);
    final speedFactor = (state.dragSpeed / 1800).clamp(0.0, 1.0);
    final hold = state.holdProgress;

    final (widthExpansion, heightExpansion) = switch (style) {
      LiquidGlassNavBarAnimationStyle.liquid => (
          _holdWidthExpansion * hold + 4 * speedFactor,
          _holdHeightExpansion * hold +
              _maxVerticalStretch * transitionPulse * travelFactor +
              22 * speedFactor,
        ),
      LiquidGlassNavBarAnimationStyle.elastic => (
          20 * hold + 24 * transitionPulse + 10 * speedFactor,
          12 * hold + 12 * transitionPulse * travelFactor + 28 * speedFactor,
        ),
      LiquidGlassNavBarAnimationStyle.pulse => (
          14 * hold + 14 * transitionPulse + 6 * speedFactor,
          14 * hold + 14 * transitionPulse + 18 * speedFactor,
        ),
      LiquidGlassNavBarAnimationStyle.smooth => (
          10 * hold + 4 * transitionPulse,
          8 * hold + 5 * transitionPulse + 10 * speedFactor,
        ),
    };

    return Rect.fromCenter(
      center: Offset(state.center, state.dockHeight / 2),
      width: state.restingRect.width + widthExpansion,
      height: state.restingRect.height + heightExpansion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dockSettings = widget.settings.tintColor == null
        ? widget.settings.copyWith(tintColor: Colors.black, tintOpacity: 0.26)
        : widget.settings;

    final scrollConfiguration = widget.scrollConfiguration;
    return AnimatedScale(
      key: const ValueKey('liquid-glass-nav-dock-scale'),
      scale: _scrollBehavior.isCollapsed
          ? scrollConfiguration?.collapsedScale ?? 1.0
          : 1.0,
      duration: scrollConfiguration?.animationDuration ?? Duration.zero,
      curve: Curves.easeOutBack,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(
              child: IgnorePointer(
                child: PlatformGlass(
                  borderRadius: widget.borderRadius,
                  settings: dockSettings,
                  useSharedBackdrop: false,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / widget.items.length;
                return Listener(
                  onPointerCancel: (_) =>
                      _finishDrag(itemWidth, selectItem: false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (details) => _startDrag(
                      details.localPosition.dx,
                      itemWidth,
                      constraints.maxWidth,
                      sourceTimeStamp: details.sourceTimeStamp,
                    ),
                    onHorizontalDragUpdate: (details) => _updateDrag(
                      details.localPosition.dx,
                      itemWidth,
                      constraints.maxWidth,
                      sourceTimeStamp: details.sourceTimeStamp,
                    ),
                    onHorizontalDragEnd: (_) =>
                        _finishDrag(itemWidth, selectItem: true),
                    onHorizontalDragCancel: () =>
                        _finishDrag(itemWidth, selectItem: false),
                    onLongPressStart: (details) => _startDrag(
                      details.localPosition.dx,
                      itemWidth,
                      constraints.maxWidth,
                    ),
                    onLongPressMoveUpdate: (details) => _updateDrag(
                      details.localPosition.dx,
                      itemWidth,
                      constraints.maxWidth,
                    ),
                    onLongPressEnd: (_) =>
                        _finishDrag(itemWidth, selectItem: true),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedBuilder(
                          animation: _indicatorAnimation,
                          builder: (context, _) {
                            final rect = _blobRect(itemWidth, widget.height);
                            return Positioned.fromRect(
                              rect: rect,
                              child: DecoratedBox(
                                key: const ValueKey(
                                    'liquid-glass-nav-indicator'),
                                decoration: BoxDecoration(
                                  color: widget.indicatorColor
                                      .withValues(alpha: 0.28),
                                  borderRadius:
                                      BorderRadius.circular(rect.height / 2),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ValueListenableBuilder<int?>(
                          valueListenable: _dragIndex,
                          builder: (context, dragIndex, _) => Row(
                            children: [
                              for (var index = 0;
                                  index < widget.items.length;
                                  index++)
                                Expanded(
                                  child: _DockItem(
                                    item: widget.items[index],
                                    isActive: index ==
                                        (dragIndex ?? widget.currentIndex),
                                    activeColor: widget.activeColor,
                                    inactiveColor: widget.inactiveColor,
                                    showLabel: widget.showLabels,
                                    onTap: () {
                                      _scrollBehavior.expand();
                                      HapticFeedback.selectionClick();
                                      widget.onTap(index);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.showLabel,
    required this.onTap,
  });

  final LiquidGlassNavItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    final icon = isActive ? (item.activeIcon ?? item.icon) : item.icon;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                scale: isActive ? 1.08 : 1,
                child: IconTheme(
                  data: IconThemeData(color: color, size: 25),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: color),
                    child: icon,
                  ),
                ),
              ),
              if (item.badge != null && item.badge! > 0)
                Positioned(
                  top: -5,
                  right: -9,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${item.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(item.label),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single item descriptor for [LiquidGlassNavBar].
class LiquidGlassNavItem {
  /// Describes one destination in a [LiquidGlassNavBar].
  ///
  /// [icon] and [activeIcon] are Flutter widgets used by the Android and
  /// fallback renderers. Native iOS uses SF Symbol names from
  /// [iosSystemImage] and [iosSelectedSystemImage].
  const LiquidGlassNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
    this.iosSystemImage,
    this.iosSelectedSystemImage,
  });

  /// Widget displayed by the Android and fallback renderers.
  ///
  /// It inherits the current [IconTheme] and [DefaultTextStyle], so omit an
  /// explicit colour when the widget should follow active/inactive styling.
  final Widget icon;

  /// Optional widget displayed while selected.
  ///
  /// When omitted, [icon] is reused.
  final Widget? activeIcon;

  /// Text displayed below the icon when the bar shows labels.
  final String label;

  /// Optional badge count.
  ///
  /// The badge is hidden when null, zero, or negative.
  final int? badge;

  /// Optional SF Symbol name used by the native iOS tab bar.
  ///
  /// If omitted, native iOS displays the `circle` SF Symbol.
  final String? iosSystemImage;

  /// Optional selected-state SF Symbol name used by the native iOS tab bar.
  ///
  /// When omitted, [iosSystemImage] is reused, including its `circle` fallback.
  final String? iosSelectedSystemImage;
}
