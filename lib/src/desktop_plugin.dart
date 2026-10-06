/// Dart-only Windows registration for the Flutter-rendered glass fallback.
///
/// Desktop rendering does not need a native method channel. This registration
/// marks Windows as an inline implementation of the plugin for Flutter tooling.
abstract final class FlutterLiquidGlassKitWindowsPlugin {
  /// Registers the Dart-only implementation.
  static void registerWith() {}
}
