import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'liquid_glass_settings.dart';

const _groupViewType = 'flutter_liquid_glass_kit/glass_group';
const _groupChannelPrefix = 'flutter_liquid_glass_kit/glass_group_';

/// Internal coordinator for one page-level native iOS glass host.
///
/// Kept outside the public library exports. [LiquidGlassBackdropGroup] owns the
/// controller and descendant [PlatformGlass] widgets register through the
/// inherited scope below.
class LiquidGlassNativeGroupController {
  final GlobalKey hostKey = GlobalKey();
  final Map<int, LiquidGlassGroupedSurfaceState> _surfaces = {};

  MethodChannel? _channel;
  int _nextSurfaceId = 0;
  bool _frameScheduled = false;
  bool _sendInProgress = false;
  bool _sendAgain = false;
  bool _disposed = false;

  int register(LiquidGlassGroupedSurfaceState surface) {
    final id = _nextSurfaceId++;
    _surfaces[id] = surface;
    scheduleSync();
    return id;
  }

  void unregister(int id) {
    _surfaces.remove(id);
    scheduleSync();
  }

  void attachPlatformView(int viewId) {
    _channel = MethodChannel('$_groupChannelPrefix$viewId');
    scheduleSync();
  }

  void scheduleSync() {
    if (_disposed || _frameScheduled) return;
    _frameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameScheduled = false;
      unawaited(_sync());
    });
  }

  Future<void> _sync() async {
    final channel = _channel;
    if (_disposed || channel == null) return;
    if (_sendInProgress) {
      _sendAgain = true;
      return;
    }

    final host = hostKey.currentContext?.findRenderObject();
    if (host is! RenderBox || !host.attached || !host.hasSize) return;

    final hostBounds = Offset.zero & host.size;
    final surfaces = <Map<String, Object?>>[];
    for (final entry in _surfaces.entries) {
      final description = entry.value.describeForHost(host, hostBounds);
      if (description != null) {
        surfaces.add(<String, Object?>{'id': entry.key, ...description});
      }
    }

    _sendInProgress = true;
    try {
      await channel.invokeMethod<void>('setSurfaces', surfaces);
    } catch (error) {
      // Platform view can disappear while an asynchronous update is queued.
      if (error is! PlatformException && error is! MissingPluginException) {
        rethrow;
      }
    } finally {
      _sendInProgress = false;
      if (_sendAgain && !_disposed) {
        _sendAgain = false;
        scheduleSync();
      }
    }
  }

  void dispose() {
    _disposed = true;
    _surfaces.clear();
    _channel = null;
  }
}

class LiquidGlassNativeGroupScope extends InheritedWidget {
  const LiquidGlassNativeGroupScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final LiquidGlassNativeGroupController controller;

  static LiquidGlassNativeGroupController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LiquidGlassNativeGroupScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(LiquidGlassNativeGroupScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Owns the single native platform view used by all glass surfaces on a page.
class LiquidGlassNativeBackdropHost extends StatefulWidget {
  const LiquidGlassNativeBackdropHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<LiquidGlassNativeBackdropHost> createState() =>
      _LiquidGlassNativeBackdropHostState();
}

class _LiquidGlassNativeBackdropHostState
    extends State<LiquidGlassNativeBackdropHost> {
  late final LiquidGlassNativeGroupController _controller =
      LiquidGlassNativeGroupController();

  bool _handleScrollNotification(ScrollNotification notification) {
    _controller.scheduleSync();
    return false;
  }

  @override
  void didUpdateWidget(covariant LiquidGlassNativeBackdropHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.scheduleSync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _controller.hostKey,
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: UiKitView(
              viewType: _groupViewType,
              hitTestBehavior: PlatformViewHitTestBehavior.transparent,
              onPlatformViewCreated: _controller.attachPlatformView,
            ),
          ),
        ),
        LiquidGlassNativeGroupScope(
          controller: _controller,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// Flutter content plus metadata for a surface rendered by the page host.
class LiquidGlassGroupedSurface extends StatefulWidget {
  const LiquidGlassGroupedSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.settings,
    required this.controller,
    required this.interactive,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final LiquidGlassSettings settings;
  final LiquidGlassNativeGroupController controller;
  final bool interactive;
  final double? width;
  final double? height;

  @override
  State<LiquidGlassGroupedSurface> createState() =>
      LiquidGlassGroupedSurfaceState();
}

class LiquidGlassGroupedSurfaceState extends State<LiquidGlassGroupedSurface> {
  final GlobalKey _renderKey = GlobalKey();
  late int _surfaceId;

  @override
  void initState() {
    super.initState();
    _surfaceId = widget.controller.register(this);
  }

  @override
  void didUpdateWidget(covariant LiquidGlassGroupedSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.unregister(_surfaceId);
      _surfaceId = widget.controller.register(this);
    }
    widget.controller.scheduleSync();
  }

  @override
  void dispose() {
    widget.controller.unregister(_surfaceId);
    super.dispose();
  }

  Map<String, Object?>? describeForHost(
    RenderBox host,
    Rect hostBounds,
  ) {
    final renderObject = _renderKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }

    final transform = renderObject.getTransformTo(host);
    final rect = MatrixUtils.transformRect(
      transform,
      Offset.zero & renderObject.size,
    );
    if (rect.isEmpty || !rect.overlaps(hostBounds)) return null;

    final radius = widget.borderRadius;
    final tintColor = widget.settings.tintColor;
    return <String, Object?>{
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
      'topLeftRadius': radius.topLeft.x,
      'topRightRadius': radius.topRight.x,
      'bottomRightRadius': radius.bottomRight.x,
      'bottomLeftRadius': radius.bottomLeft.x,
      'tintColorHex': tintColor == null
          ? null
          : '#${tintColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      'tintOpacity': widget.settings.tintOpacity,
      'iosGlassStyle': widget.settings.iosGlassStyle.name,
      'interactive': widget.interactive,
    };
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.scheduleSync();
    return SizedBox(
      key: _renderKey,
      width: widget.width,
      height: widget.height,
      child: widget.child,
    );
  }
}
