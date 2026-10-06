import AppKit
import Combine
import FlutterMacOS
import SwiftUI

private let surfaceViewType = "flutter_liquid_glass_kit/glass_surface"
private let groupViewType = "flutter_liquid_glass_kit/glass_group"
private let groupChannelPrefix = "flutter_liquid_glass_kit/glass_group_"

public class FlutterLiquidGlassKitMacOSPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger
    registrar.register(
      LiquidGlassSurfaceFactory(),
      withId: surfaceViewType
    )
    registrar.register(
      LiquidGlassGroupFactory(messenger: messenger),
      withId: groupViewType
    )
  }
}

private final class LiquidGlassSurfaceFactory: NSObject, FlutterPlatformViewFactory {
  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    LiquidGlassSurfaceView(arguments: args as? [String: Any])
  }
}

private final class LiquidGlassGroupFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    LiquidGlassGroupView(viewIdentifier: viewId, messenger: messenger)
  }
}

private final class LiquidGlassSurfaceView: NSView {
  private var hostingController: NSViewController?

  init(arguments: [String: Any]?) {
    super.init(frame: .zero)
    let descriptor = LiquidGlassSurfaceDescriptor(arguments: arguments, id: 0)
    install(rootView: descriptor.rootView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func install(rootView: AnyView) {
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor

    let controller = NSHostingController(rootView: rootView)
    controller.view.frame = bounds
    controller.view.autoresizingMask = [.width, .height]
    controller.view.wantsLayer = true
    controller.view.layer?.backgroundColor = NSColor.clear.cgColor
    addSubview(controller.view)
    hostingController = controller
  }
}

private struct LiquidGlassSurfaceDescriptor: Identifiable {
  let id: Int64
  let frame: CGRect
  let cornerRadii: LiquidGlassCornerRadii
  let tintOpacity: Double
  let tintColorHex: String?
  let glassStyle: String
  let interactive: Bool

  init(arguments: [String: Any]?, id fallbackId: Int64) {
    id = (arguments?["id"] as? NSNumber)?.int64Value ?? fallbackId
    frame = CGRect(
      x: finiteNumber(arguments?["x"], fallback: 0),
      y: finiteNumber(arguments?["y"], fallback: 0),
      width: nonnegativeValue(arguments?["width"], fallback: 0),
      height: nonnegativeValue(arguments?["height"], fallback: 0)
    )
    cornerRadii = LiquidGlassCornerRadii(arguments: arguments)
    tintOpacity = unitValue(arguments?["tintOpacity"], fallback: 0.15)
    tintColorHex = arguments?["tintColorHex"] as? String
    glassStyle = arguments?["iosGlassStyle"] as? String ?? "system"
    interactive = arguments?["interactive"] as? Bool ?? false
  }

  var hasVisibleSize: Bool {
    frame.width > 0 && frame.height > 0
  }

  var rootView: AnyView {
    if #available(macOS 26.0, *) {
      return AnyView(
        LiquidGlassSurface(
          cornerRadii: cornerRadii,
          tintOpacity: tintOpacity,
          tintColorHex: tintColorHex,
          glassStyle: glassStyle,
          interactive: interactive
        )
      )
    }
    return AnyView(
      LegacyLiquidGlassSurface(
        cornerRadii: cornerRadii,
        tintOpacity: tintOpacity,
        tintColorHex: tintColorHex
      )
    )
  }
}

private final class LiquidGlassGroupModel: ObservableObject {
  @Published var surfaces: [LiquidGlassSurfaceDescriptor] = []
}

private final class LiquidGlassGroupView: NSView {
  private let channel: FlutterMethodChannel
  private let model = LiquidGlassGroupModel()
  private var hostingController: NSViewController?

  init(viewIdentifier viewId: Int64, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "\(groupChannelPrefix)\(viewId)",
      binaryMessenger: messenger
    )
    super.init(frame: .zero)
    installHost()
    installChannelHandler()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  private func installHost() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    layer?.masksToBounds = true

    let rootView: AnyView
    if #available(macOS 26.0, *) {
      rootView = AnyView(LiquidGlassGroup(model: model))
    } else {
      rootView = AnyView(LegacyLiquidGlassGroup(model: model))
    }

    let controller = NSHostingController(rootView: rootView)
    controller.view.frame = bounds
    controller.view.autoresizingMask = [.width, .height]
    controller.view.wantsLayer = true
    controller.view.layer?.backgroundColor = NSColor.clear.cgColor
    addSubview(controller.view)
    hostingController = controller
  }

  private func installChannelHandler() {
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      guard call.method == "setSurfaces" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let arguments = call.arguments as? [[String: Any]] ?? []
      self.model.surfaces = arguments
        .enumerated()
        .map { LiquidGlassSurfaceDescriptor(arguments: $0.element, id: Int64($0.offset)) }
        .filter(\.hasVisibleSize)
      result(nil)
    }
  }
}

private struct LegacyLiquidGlassGroup: View {
  @ObservedObject var model: LiquidGlassGroupModel

  var body: some View {
    ZStack(alignment: .topLeading) {
      Color.clear
      ForEach(model.surfaces) { surface in
        surface.rootView
          .frame(width: surface.frame.width, height: surface.frame.height)
          .offset(x: surface.frame.minX, y: surface.frame.minY)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

@available(macOS 26.0, *)
private struct LiquidGlassGroup: View {
  @ObservedObject var model: LiquidGlassGroupModel

  var body: some View {
    GlassEffectContainer(spacing: 0) {
      ZStack(alignment: .topLeading) {
        Color.clear
        ForEach(model.surfaces) { surface in
          LiquidGlassSurface(
            cornerRadii: surface.cornerRadii,
            tintOpacity: surface.tintOpacity,
            tintColorHex: surface.tintColorHex,
            glassStyle: surface.glassStyle,
            interactive: surface.interactive
          )
          .frame(width: surface.frame.width, height: surface.frame.height)
          .offset(x: surface.frame.minX, y: surface.frame.minY)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }
}

private struct LiquidGlassCornerRadii {
  let topLeft: CGFloat
  let topRight: CGFloat
  let bottomRight: CGFloat
  let bottomLeft: CGFloat

  init(arguments: [String: Any]?) {
    func radius(_ key: String) -> CGFloat {
      CGFloat(nonnegativeValue(arguments?[key], fallback: 24))
    }
    topLeft = radius("topLeftRadius")
    topRight = radius("topRightRadius")
    bottomRight = radius("bottomRightRadius")
    bottomLeft = radius("bottomLeftRadius")
  }
}

private struct LiquidGlassRoundedShape: Shape {
  let radii: LiquidGlassCornerRadii

  func path(in rect: CGRect) -> Path {
    let maximumRadius = min(rect.width, rect.height) / 2
    let topLeft = min(max(radii.topLeft, 0), maximumRadius)
    let topRight = min(max(radii.topRight, 0), maximumRadius)
    let bottomRight = min(max(radii.bottomRight, 0), maximumRadius)
    let bottomLeft = min(max(radii.bottomLeft, 0), maximumRadius)

    var path = Path()
    path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
    if topRight > 0 {
      path.addArc(
        center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
        radius: topRight,
        startAngle: .degrees(-90),
        endAngle: .degrees(0),
        clockwise: false
      )
    }
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
    if bottomRight > 0 {
      path.addArc(
        center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
        radius: bottomRight,
        startAngle: .degrees(0),
        endAngle: .degrees(90),
        clockwise: false
      )
    }
    path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
    if bottomLeft > 0 {
      path.addArc(
        center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
        radius: bottomLeft,
        startAngle: .degrees(90),
        endAngle: .degrees(180),
        clockwise: false
      )
    }
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
    if topLeft > 0 {
      path.addArc(
        center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
        radius: topLeft,
        startAngle: .degrees(180),
        endAngle: .degrees(270),
        clockwise: false
      )
    }
    path.closeSubpath()
    return path
  }
}

private struct LegacyLiquidGlassSurface: View {
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.colorSchemeContrast) private var contrast

  let cornerRadii: LiquidGlassCornerRadii
  let tintOpacity: Double
  let tintColorHex: String?

  private var tintColor: Color {
    Color(nsColor: color(from: tintColorHex ?? "#FFFFFFFF"))
  }

  private var effectiveTintOpacity: Double {
    min(max(tintOpacity + (contrast == .increased ? 0.20 : 0), 0), 1)
  }

  var body: some View {
    let shape = LiquidGlassRoundedShape(radii: cornerRadii)
    ZStack {
      if reduceTransparency {
        shape.fill(tintColor.opacity(max(effectiveTintOpacity, 0.82)))
      } else {
        shape.fill(.ultraThinMaterial)
        shape.fill(tintColor.opacity(effectiveTintOpacity))
      }
    }
    .overlay(
      shape.stroke(
        Color.white.opacity(contrast == .increased ? 0.58 : 0.25),
        lineWidth: contrast == .increased ? 1.5 : 1
      )
    )
    .clipShape(shape)
  }
}

@available(macOS 26.0, *)
private struct LiquidGlassSurface: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.colorSchemeContrast) private var contrast

  let cornerRadii: LiquidGlassCornerRadii
  let tintOpacity: Double
  let tintColorHex: String?
  let glassStyle: String
  let interactive: Bool

  private var tintColor: Color {
    Color(nsColor: color(from: tintColorHex ?? "#FFFFFFFF"))
  }

  private var effectiveTintOpacity: Double {
    min(max(tintOpacity + (contrast == .increased ? 0.20 : 0), 0), 1)
  }

  private var style: Glass {
    glassStyle == "clear" ? Glass.clear : Glass.regular
  }

  var body: some View {
    let shape = LiquidGlassRoundedShape(radii: cornerRadii)
    if reduceTransparency {
      shape
        .fill(tintColor.opacity(max(effectiveTintOpacity, 0.82)))
        .overlay(
          shape.stroke(
            Color.white.opacity(contrast == .increased ? 0.64 : 0.36),
            lineWidth: contrast == .increased ? 1.5 : 1
          )
        )
    } else {
      Color.clear
        .glassEffect(
          style
            .tint(tintColor.opacity(effectiveTintOpacity))
            .interactive(interactive && !reduceMotion),
          in: shape
        )
    }
  }
}

private func color(from hex: String) -> NSColor {
  var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
  if value.hasPrefix("#") { value.removeFirst() }
  guard value.count == 6 || value.count == 8, let raw = UInt64(value, radix: 16) else {
    return .white
  }

  let alpha: CGFloat
  let red: CGFloat
  let green: CGFloat
  let blue: CGFloat
  if value.count == 8 {
    alpha = CGFloat((raw >> 24) & 0xFF) / 255
    red = CGFloat((raw >> 16) & 0xFF) / 255
    green = CGFloat((raw >> 8) & 0xFF) / 255
    blue = CGFloat(raw & 0xFF) / 255
  } else {
    alpha = 1
    red = CGFloat((raw >> 16) & 0xFF) / 255
    green = CGFloat((raw >> 8) & 0xFF) / 255
    blue = CGFloat(raw & 0xFF) / 255
  }
  return NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

private func finiteNumber(_ value: Any?, fallback: Double) -> Double {
  guard let number = value as? NSNumber else { return fallback }
  let candidate = number.doubleValue
  return candidate.isFinite ? candidate : fallback
}

private func unitValue(_ value: Any?, fallback: Double) -> Double {
  min(max(finiteNumber(value, fallback: fallback), 0), 1)
}

private func nonnegativeValue(_ value: Any?, fallback: Double) -> Double {
  max(finiteNumber(value, fallback: fallback), 0)
}
