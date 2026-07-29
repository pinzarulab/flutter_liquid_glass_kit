import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass_settings.dart';
import 'platform_glass.dart';

/// A Flutter text field presented on a platform-adaptive glass surface.
///
/// Text editing remains in Flutter so controllers, focus, selection, autofill,
/// formatters, and keyboard behavior work consistently. On supported iOS
/// versions, [PlatformGlass] renders the surface behind the field with native
/// SwiftUI glass.
class LiquidGlassTextField extends StatelessWidget {
  /// Creates a text field with a Liquid Glass background.
  const LiquidGlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.autofillHints,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20),
    this.enableInteractiveSelection,
    this.cursorColor,
    LiquidGlassSettings? settings,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.useSharedBackdrop = true,
    this.width,
    this.height,
  }) : _settings = settings;

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Controls and observes keyboard focus.
  final FocusNode? focusNode;

  /// Labels, hints, icons, counters, and optional custom borders.
  ///
  /// Missing borders default to [InputBorder.none] because the glass surface
  /// provides the field outline.
  final InputDecoration decoration;

  /// Type of keyboard requested from the operating system.
  final TextInputType? keyboardType;

  /// Action button shown by the software keyboard.
  final TextInputAction? textInputAction;

  /// Automatic capitalization behavior for the software keyboard.
  final TextCapitalization textCapitalization;

  /// Style used for editable text.
  final TextStyle? style;

  /// Horizontal alignment of editable text.
  final TextAlign textAlign;

  /// Explicit text direction, or null to use the ambient direction.
  final TextDirection? textDirection;

  /// Whether the field requests focus when first built.
  final bool autofocus;

  /// Whether text can be selected but not changed.
  final bool readOnly;

  /// Whether the field accepts input.
  final bool? enabled;

  /// Whether the entered value is replaced by [obscuringCharacter].
  final bool obscureText;

  /// Character displayed for obscured text.
  final String obscuringCharacter;

  /// Whether the keyboard may automatically correct entered text.
  final bool autocorrect;

  /// Whether the keyboard may display input suggestions.
  final bool enableSuggestions;

  /// Maximum number of visible lines.
  final int? maxLines;

  /// Minimum number of visible lines.
  final int? minLines;

  /// Maximum number of characters, or null for no limit.
  final int? maxLength;

  /// Optional transforms and restrictions applied to entered text.
  final List<TextInputFormatter>? inputFormatters;

  /// Called whenever the value changes.
  final ValueChanged<String>? onChanged;

  /// Called when editing completes.
  final VoidCallback? onEditingComplete;

  /// Called when the keyboard action submits the value.
  final ValueChanged<String>? onSubmitted;

  /// Called when the field is tapped.
  final GestureTapCallback? onTap;

  /// Autofill classifications such as [AutofillHints.email].
  final Iterable<String>? autofillHints;

  /// Brightness requested for the software keyboard.
  final Brightness? keyboardAppearance;

  /// Padding kept visible when the field scrolls above the software keyboard.
  final EdgeInsets scrollPadding;

  /// Whether selection handles and the selection toolbar are available.
  final bool? enableInteractiveSelection;

  /// Optional caret colour.
  final Color? cursorColor;

  final LiquidGlassSettings? _settings;

  /// The locally supplied settings, or [LiquidGlassSettings.matteLight] when
  /// no local settings were supplied.
  LiquidGlassSettings get settings =>
      _settings ?? LiquidGlassSettings.matteLight;

  /// Shape of the glass surface and clipping boundary.
  final BorderRadius borderRadius;

  /// Default field padding when [decoration] does not provide its own.
  final EdgeInsetsGeometry contentPadding;

  /// Whether Android can share a grouped backdrop pass with sibling surfaces.
  final bool useSharedBackdrop;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveSettings = LiquidGlassSettings.resolve(context, _settings);
    final fallbackBorder = decoration.border ?? InputBorder.none;
    final effectiveDecoration = decoration.copyWith(
      border: fallbackBorder,
      enabledBorder: decoration.enabledBorder ?? fallbackBorder,
      disabledBorder: decoration.disabledBorder ?? fallbackBorder,
      focusedBorder: decoration.focusedBorder ?? fallbackBorder,
      errorBorder: decoration.errorBorder ?? fallbackBorder,
      focusedErrorBorder: decoration.focusedErrorBorder ?? fallbackBorder,
      contentPadding: decoration.contentPadding ?? contentPadding,
    );

    return PlatformGlass(
      borderRadius: borderRadius,
      settings: effectiveSettings,
      useSharedBackdrop: useSharedBackdrop,
      width: width,
      height: height,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: effectiveDecoration,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          style: style,
          textAlign: textAlign,
          textDirection: textDirection,
          autofocus: autofocus,
          readOnly: readOnly,
          enabled: enabled,
          obscureText: obscureText,
          obscuringCharacter: obscuringCharacter,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onSubmitted: onSubmitted,
          onTap: onTap,
          autofillHints: autofillHints,
          keyboardAppearance: keyboardAppearance,
          scrollPadding: scrollPadding,
          enableInteractiveSelection: enableInteractiveSelection,
          cursorColor: cursorColor,
        ),
      ),
    );
  }
}
