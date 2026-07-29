# flutter_liquid_glass_kit

Platform-adaptive Liquid Glass components for Flutter. The package uses native
SwiftUI glass on iOS and an optimized Flutter matte-glass renderer elsewhere.

| Platform | Renderer |
|---|---|
| iOS 26+ | Native SwiftUI `.glassEffect()` |
| iOS 16-25 | Native system-material fallback |
| Android, web, desktop | Flutter blur, tint, highlight, border, and shadow |

## Installation

```bash
flutter pub add flutter_liquid_glass_kit
```

```dart
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';
```

## Components

### Card

```dart
const LiquidGlassCard(
  padding: EdgeInsets.all(20),
  child: Text('Hello, Glass!'),
)
```

`width` and `height` are optional fixed dimensions. When they are omitted, the
card follows its parent constraints and child size. `margin` is outside the
glass surface; `padding` is inside it.

### Button

```dart
LiquidGlassButton(
  onPressed: () {},
  isLoading: false,
  child: const Text('Continue'),
)
```

A null `onPressed` disables the button. `isLoading: true` also disables taps and
replaces the child with a progress indicator. Use `pressScaleFactor` and
`animationDuration` to customize press feedback.

### Navigation bar

`LiquidGlassNavBar` is a normal layout widget. It is controlled: update
`currentIndex` from `onTap`.

```dart
Scaffold(
  body: pages[currentIndex],
  bottomNavigationBar: SafeArea(
    minimum: const EdgeInsets.all(16),
    child: LiquidGlassNavBar(
      currentIndex: currentIndex,
      onTap: (index) => setState(() => currentIndex = index),
      items: const [
        LiquidGlassNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          iosSystemImage: 'house',
          iosSelectedSystemImage: 'house.fill',
        ),
        LiquidGlassNavItem(
          icon: Icons.search,
          label: 'Search',
          androidIcon: Text('S'),
        ),
      ],
    ),
  ),
)
```

Use `LiquidGlassFloatingNavBar` inside a `Stack` when content should continue
behind the bar:

```dart
Stack(
  children: [
    pages[currentIndex],
    LiquidGlassFloatingNavBar(
      child: LiquidGlassNavBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: items,
      ),
    ),
  ],
)
```

The floating wrapper applies horizontal padding and includes the bottom safe
area by default. Set `respectSafeArea: false` only when an ancestor already
handles it.

On the Flutter fallback, users can hold and drag the selection indicator. Icons
and labels preview the item under the indicator, but navigation occurs only
after release. Cancelling restores the current item.

iOS and Android can optionally shrink the bar while a vertical scrollable
moves down, then restore it as soon as scrolling moves up or after an idle
delay. One configuration applies to both platforms:

```dart
LiquidGlassNavBar(
  currentIndex: currentIndex,
  onTap: onTap,
  scrollConfiguration: const LiquidGlassNavBarScrollConfiguration(
    collapsedScale: 0.82,
    collapseThreshold: 12,
    animationDuration: Duration(milliseconds: 280),
    idleExpandDuration: Duration(seconds: 5),
  ),
  items: items,
)
```

Use `iosScrollConfiguration` or `androidScrollConfiguration` only when one
platform needs different values. The former
`LiquidGlassIOSNavBarScrollConfiguration` and
`LiquidGlassAndroidNavBarScrollConfiguration` names remain as deprecated type
aliases.

The behavior also expands at the top and when an item is selected. It listens
through the nearest `ScrollNotificationObserver`; a `Scaffold` supplies one
automatically. Wrap custom layouts in `ScrollNotificationObserver` when no
`Scaffold` ancestor is present. Each configuration is ignored outside its
target platform, and both are ignored on web and desktop.

`androidIcon` and `activeAndroidIcon` accept arbitrary widgets. They inherit
the active `IconTheme` and `DefaultTextStyle`. Native iOS uses SF Symbol names
from `iosSystemImage` and `iosSelectedSystemImage`, with automatic mappings for
common Material icons.

## Native iOS fidelity

Native surfaces preserve all four Flutter corner radii. On iOS 26 each surface
is rendered inside a SwiftUI `GlassEffectContainer`; Reduce Transparency
replaces blur with a strong opaque tint, Increase Contrast strengthens tint and
borders, and Reduce Motion disables interactive glass and nav spring motion.
iOS 16-25 uses the same per-corner shape and accessibility adaptations with
system material.

Each `PlatformGlass` is a separate `UiKitView`, so its
`GlassEffectContainer` cannot merge or morph with containers hosted by sibling
platform views. True cross-widget morphing requires a future single native host
that receives all Flutter surface geometries.

## Shared settings

Define a baseline once with `LiquidGlassSettingsScope`:

```dart
LiquidGlassSettingsScope(
  settings: LiquidGlassSettings.matteDark.copyWith(
    tintColor: const Color(0xFF9333EA),
    tintOpacity: 0.30,
  ),
  child: const MyAppContent(),
)
```

Or define settings while grouping non-overlapping fallback surfaces:

```dart
LiquidGlassBackdropGroup(
  settings: const LiquidGlassSettings.matteDark,
  child: ListView(children: glassCards),
)
```

Settings resolve in this order:

1. Settings passed directly to a card, button, nav bar, or `PlatformGlass`.
2. The nearest `LiquidGlassSettingsScope` or configured backdrop group.
3. `LiquidGlassSettings.matteLight`.

A component can override the shared baseline:

```dart
const LiquidGlassCard(
  settings: LiquidGlassSettings(
    tintColor: Color(0xFF16A34A),
    tintOpacity: 0.32,
  ),
  child: Text('Local green tint'),
)
```

## Settings reference

| Parameter | Default | Behavior |
|---|---:|---|
| `tintColor` | `null` | Custom surface color. Null selects an adaptive matte tint on the fallback. |
| `tintOpacity` | `0.15` | Tint strength from `0.0` to `1.0`. Saturated colors usually work well at `0.20-0.40`. |
| `blurSigma` | `20` | Requested backdrop blur. Forwarded to native iOS and capped on Android. |
| `androidBlurSigma` | `12` | Maximum Android blur. Set to `0` for a fast matte-only surface. |
| `borderOpacity` | `0.25` | Fallback border-highlight opacity. |
| `borderWidth` | `1` | Fallback border width in logical pixels. |
| `shadowOpacity` | `0.12` | Fallback drop-shadow opacity. Set to `0` on dense screens to reduce paint cost. |
| `shadowBlurRadius` | `16` | Fallback shadow blur radius. |
| `shadowOffset` | `(0, 4)` | Fallback shadow offset. |

Built-in presets:

- `LiquidGlassSettings.matteLight`: bright neutral glass.
- `LiquidGlassSettings.matteDark`: strong charcoal glass with a lower Android
  blur cap.

For a visible custom tint, provide both color and opacity:

```dart
const LiquidGlassSettings(
  tintColor: Color(0xFF9333EA),
  tintOpacity: 0.30,
)
```

## Android performance

Wrap scrollable sections containing several non-overlapping glass surfaces in
`LiquidGlassBackdropGroup`. It shares backdrop input and, by default, pauses
blur while scrolling while preserving tint, border, and content:

```dart
LiquidGlassBackdropGroup(
  disableBlurWhileScrolling: true,
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => LiquidGlassCard(
      child: ItemRow(items[index]),
    ),
  ),
)
```

Set `disableBlurWhileScrolling: false` to keep blur active during motion. Other
useful optimizations:

- Lower `androidBlurSigma` to `6-8`, or `0` for matte-only rendering.
- Reduce `shadowBlurRadius` or set `shadowOpacity` to `0` in long lists.
- Use lazy lists such as `ListView.builder`.
- Avoid continuously animated backgrounds behind large blurred surfaces.
- Use `LiquidGlassScrollBehavior` to remove Android overscroll effects that can
  alter backdrop sampling.

Do not put overlapping `PageView` pages, route transitions, or floating surfaces
in one backdrop group. Grouped filters share input and overlapping surfaces can
sample the wrong backdrop. `LiquidGlassNavBar` already disables shared backdrop
filtering for its floating fallback surface.

## Rendering mode

```dart
if (isNativeLiquidGlassSupported) {
  print('Native iOS surface');
} else {
  print('Flutter fallback surface');
}
```

This value is true on iOS even before iOS 26 because those systems still use a
native material fallback. Android, web, and desktop return false.

## Requirements

- Flutter 3.19 or newer
- Dart 3.0 or newer
- iOS 16+; iOS 26+ uses native Liquid Glass
- Android API 21+
