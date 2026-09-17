import 'package:flutter/material.dart';

import 'liquid_glass_settings.dart';
import 'platform_glass.dart';

/// A pressable glass-effect button.
///
/// Wraps any [child] in the Liquid Glass surface and handles tap,
/// scale feedback, and an optional loading state.
///
/// ```dart
/// LiquidGlassButton(
///   onPressed: () => print('tapped'),
///   child: Text('Get Started'),
/// )
/// ```
class LiquidGlassButton extends StatefulWidget {
  /// Creates an interactive glass button.
  ///
  /// The button is disabled when [onPressed] is null or [isLoading] is true.
  /// When `settings` is omitted, settings are inherited from the nearest
  /// shared settings scope before falling back to
  /// [LiquidGlassSettings.matteLight].
  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    LiquidGlassSettings? settings,
    this.androidColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.isLoading = false,
    this.pressScaleFactor = 0.96,
    this.animationDuration = const Duration(milliseconds: 120),
  }) : _settings = settings;

  /// Content displayed when [isLoading] is false.
  final Widget child;

  /// Called after a successful tap.
  ///
  /// Set to null to disable interaction and render a subdued tint.
  final VoidCallback? onPressed;
  final LiquidGlassSettings? _settings;

  /// Optional solid Android color for this button.
  ///
  /// This overrides inherited [LiquidGlassSettings.androidColor] and disables
  /// Android glass effects for this button. It has no effect on other
  /// platforms.
  final Color? androidColor;

  /// The locally supplied settings, or [LiquidGlassSettings.matteLight] when
  /// no local settings were supplied.
  ///
  /// The effective inherited value is resolved during build.
  LiquidGlassSettings get settings =>
      _settings ?? LiquidGlassSettings.matteLight;

  /// Shape of the glass surface and its clipping boundary.
  final BorderRadius borderRadius;

  /// Space between the glass edge and [child].
  final EdgeInsetsGeometry padding;

  /// Whether to show a [CircularProgressIndicator] instead of [child].
  ///
  /// Loading also disables [onPressed].
  final bool isLoading;

  /// Scale applied while pressed, normally between `0.0` and `1.0`.
  ///
  /// The default `0.96` provides subtle tactile feedback.
  final double pressScaleFactor;

  /// Duration of the press and release scale animation.
  final Duration animationDuration;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScaleFactor,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _scaleController.duration = widget.animationDuration;
    }
    if (oldWidget.pressScaleFactor != widget.pressScaleFactor) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.pressScaleFactor,
      ).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
    }
  }

  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    var effectiveSettings = LiquidGlassSettings.resolve(
      context,
      widget._settings,
    );
    if (widget.androidColor != null) {
      effectiveSettings = effectiveSettings.copyWith(
        androidColor: widget.androidColor,
      );
    }
    return Semantics(
      button: true,
      enabled: _isEnabled,
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => _scaleController.forward() : null,
        onTap: _isEnabled ? widget.onPressed : null,
        onTapUp: _isEnabled ? (_) => _scaleController.reverse() : null,
        onTapCancel: _isEnabled ? _onTapCancel : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: PlatformGlass(
            borderRadius: widget.borderRadius,
            interactive: _isEnabled,
            settings: _isEnabled
                ? effectiveSettings
                : effectiveSettings.copyWith(
                    tintOpacity: effectiveSettings.tintOpacity * 0.5,
                  ),
            child: Padding(
              padding: widget.padding,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
