## 1.4.1

- Add shared Backdrop Filters that fixes Android rendering differences between the first visible grouped surface and its siblings while scrolling.

## 1.4.0

- Add exact solid-color Android rendering with no blur, gradient, border, or shadow.
- Add `androidColor` shortcuts to cards and buttons.
- Support page-level solid Android styles through existing settings scopes and backdrop groups, while preserving per-component overrides.

## 1.3.1

- Make `LiquidGlassNavItem.icon` and `activeIcon` Widget-only and remove Material code-point and Android-specific icon fields.

## 1.3.0

- Stretch the Android navigation indicator vertically in response to horizontal drag speed, with a short decay when movement pauses.
- Add `liquid`, `elastic`, `pulse`, and `smooth` Android navigation animation styles.
- Add `LiquidGlassNavBarAnimationResolver` and `LiquidGlassNavBarAnimationState` for custom indicator geometry.

## 1.2.1

- Clamp native iOS colour components and render iOS 26 surfaces with `glassEffect` directly to reduce drawable pressure.
- Add a configurable upward-scroll threshold before the navigation bar expands.
- Improve Android scrolling performance by lowering the default blur cap, pausing blur and shadows without remounting descendants, and delaying effect restoration until scrolling settles.
- Add `LiquidGlassTextField`, keeping Flutter text editing over the platform-adaptive glass surface.

## 1.2.0

- Make `LiquidGlassNavBar` a normal layout widget and add `LiquidGlassFloatingNavBar` for safe-area-aware floating placement.
- Unify iOS and Android scroll resizing under `LiquidGlassNavBarScrollConfiguration`, retaining deprecated platform-specific type aliases.
- Preserve all four corner radii in native iOS surfaces.
- Render iOS 26 surfaces inside `GlassEffectContainer` and adapt native/fallback rendering for Reduce Transparency and Increase Contrast.
- Respect Reduce Motion in native iOS glass and navigation animations.

## 1.1.0

- Add configurable Android nav-bar collapse on downward scrolling, with upward-scroll and five-second idle expansion.
- Reduce the native iOS nav bar's default bottom spacing while keeping Android spacing unchanged.

## 1.0.6

- Add configurable native iOS nav-bar collapse on downward scrolling, with upward-scroll and five-second idle expansion.
- Expand README guidance and document all public constructors and parameters.

## 1.0.5

- Preserve custom Android tint colors through the glass highlight gradient instead of washing them out with white.
- Make `LiquidGlassSettings.matteDark` render a clearly dark matte surface and inherit correctly through performance-only backdrop groups.
- Add shared baseline settings through `LiquidGlassBackdropGroup`, with per-component overrides.
- Improve Android scrolling performance by pausing grouped backdrop blur during motion, retaining stable backdrop keys, and isolating nav drag repaints.

## 1.0.4

- Improve the Android navigation indicator with finger-following drag selection, active item previews, press expansion, and an iOS-style vertical stretch during tab jumps.
- Add Android widget icons for `LiquidGlassNavItem`.
- Scope example backdrop groups per page to keep Android glass colors stable during horizontal navigation.

## 1.0.3

- Add `LiquidGlassScrollBehavior` to keep Android glass colors stable during overscroll.

## 1.0.2

- Added pages for example app.
- Improve animation for android navigation bar.
- Improve native iOS usage.

## 1.0.1

- Prepare the package for a `1.0.1` patch release.
- Format the example search item list.

## 1.0.0

- Initial release as `flutter_liquid_glass_kit`.
- Add Swift Package Manager support for iOS plugin consumers.
- Render Liquid Glass natively on iOS with SwiftUI glass surfaces.
- Add native iOS floating tab bar support.
- Add optimized Flutter matte-glass fallback for Android and other platforms.
- Add reusable glass card, button, and navigation bar widgets.
- Add runnable example app.
