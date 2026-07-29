import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass_settings.dart';
import 'platform_glass.dart';

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
///         LiquidGlassNavItem(icon: Icons.home, label: 'Home'),
///         LiquidGlassNavItem(icon: Icons.search, label: 'Search'),
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
              'iconCodePoint': item.icon.codePoint,
              'activeIconCodePoint': item.activeIcon?.codePoint,
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
  final LiquidGlassNavBarScrollConfiguration? scrollConfiguration;

  @override
  State<_LiquidGlassDock> createState() => _LiquidGlassDockState();
}

class _LiquidGlassDockState extends State<_LiquidGlassDock>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _holdController;
  late final Listenable _indicatorAnimation;
  late final ValueNotifier<double?> _dragCenter;
  late final ValueNotifier<int?> _dragIndex;
  late double _fromPosition;
  late double _toPosition;
  late final _NavBarScrollBehavior _scrollBehavior;

  static const _duration = Duration(milliseconds: 550);
  static const _holdDuration = Duration(milliseconds: 180);
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
    _indicatorAnimation = Listenable.merge([
      _controller,
      _holdController,
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
    final t = Curves.easeOutCubic.transform(_controller.value);
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

  void _startDrag(double center, double itemWidth, double dockWidth) {
    _controller.stop();
    _holdController.forward();
    final clamped = _clampDragCenter(center, itemWidth, dockWidth);
    _dragIndex.value = _indexForCenter(clamped, itemWidth);
    _dragCenter.value = clamped;
  }

  void _updateDrag(double center, double itemWidth, double dockWidth) {
    final clamped = _clampDragCenter(center, itemWidth, dockWidth);
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
    _dragCenter.dispose();
    _dragIndex.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Computes the current geometry of the liquid indicator.
  ///
  /// The center eases from [_fromPosition] to [_toPosition]. Independently, a
  /// bell-shaped stretch factor (0 at start/end, peak at the midpoint)
  /// grows the blob vertically, then settles back to the resting pill shape.
  Rect _blobRect(double itemWidth, double dockHeight) {
    final dragCenter = _dragCenter.value;
    if (dragCenter != null) {
      final restWidth = itemWidth - 8;
      final restHeight = dockHeight - 8;
      return Rect.fromCenter(
        center: Offset(dragCenter, dockHeight / 2),
        width: restWidth + _holdWidthExpansion * _holdController.value,
        height: restHeight + _holdHeightExpansion * _holdController.value,
      );
    }

    final t = _controller.value;
    final positionT = Curves.easeOutCubic.transform(t);

    final fromCenter = (_fromPosition + 0.5) * itemWidth;
    final toCenter = (_toPosition + 0.5) * itemWidth;
    final center = _lerp(fromCenter, toCenter, positionT);

    // Bell curve: 0 at t=0 and t=1, 1 at t=0.5.
    final stretch = math.sin(math.pi * t);

    // Scale the stretch by travel distance so an adjacent-tab tap doesn't
    // balloon as dramatically as a jump across the whole dock.
    final travel = (toCenter - fromCenter).abs();
    final travelFactor = (travel / (itemWidth * 1.5)).clamp(0.65, 1.0);

    final restWidth = itemWidth - 8;
    final restHeight = dockHeight - 8;

    final width = restWidth + _holdWidthExpansion * _holdController.value;
    final height = restHeight +
        _maxVerticalStretch * stretch * travelFactor +
        _holdHeightExpansion * _holdController.value;

    final left = center - width / 2;
    final top = (dockHeight - height) / 2;

    return Rect.fromLTWH(left, top, width, height);
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
                    ),
                    onHorizontalDragUpdate: (details) => _updateDrag(
                      details.localPosition.dx,
                      itemWidth,
                      constraints.maxWidth,
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
    final fallbackIcon = isActive ? (item.activeIcon ?? item.icon) : item.icon;
    final icon = isActive
        ? (item.activeAndroidIcon ?? item.androidIcon)
        : item.androidIcon;
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
                    child: icon ?? Icon(fallbackIcon),
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
  /// [icon] and [label] provide cross-platform fallbacks. Android can replace
  /// the icon with arbitrary widgets through [androidIcon] and
  /// [activeAndroidIcon]. iOS can use explicit SF Symbol names through
  /// [iosSystemImage] and [iosSelectedSystemImage].
  const LiquidGlassNavItem({
    required this.icon,
    this.activeIcon,
    this.androidIcon,
    this.activeAndroidIcon,
    required this.label,
    this.badge,
    this.iosSystemImage,
    this.iosSelectedSystemImage,
  });

  /// Material icon used by the Flutter fallback and for automatic SF Symbol
  /// mapping when no platform-specific icon is supplied.
  final IconData icon;

  /// Optional icon shown when this item is selected.
  final IconData? activeIcon;

  /// Optional widget rendered by the Flutter fallback nav bar on Android and
  /// other non-iOS platforms.
  ///
  /// If omitted, [icon] is rendered as a normal [Icon]. The widget inherits an
  /// [IconTheme] and [DefaultTextStyle] with the current active/inactive color.
  final Widget? androidIcon;

  /// Optional widget rendered by the Flutter fallback nav bar when selected.
  ///
  /// If omitted, [androidIcon] is reused. If both widget fields are omitted,
  /// [activeIcon] falls back to [icon].
  final Widget? activeAndroidIcon;

  /// Text displayed below the icon when the bar shows labels.
  final String label;

  /// Optional badge count.
  ///
  /// The badge is hidden when null, zero, or negative.
  final int? badge;

  /// Optional SF Symbol name used by the native iOS tab bar.
  ///
  /// If omitted, the plugin maps common Material icons to SF Symbols.
  final String? iosSystemImage;

  /// Optional selected-state SF Symbol name used by the native iOS tab bar.
  ///
  /// When omitted, [iosSystemImage] or the automatic Material-icon mapping is
  /// reused.
  final String? iosSelectedSystemImage;
}
