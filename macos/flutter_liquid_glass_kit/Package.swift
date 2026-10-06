// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "flutter_liquid_glass_kit",
  platforms: [.macOS("12.0")],
  products: [
    .library(
      name: "flutter-liquid-glass-kit",
      targets: ["flutter_liquid_glass_kit"]
    ),
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
  ],
  targets: [
    .target(
      name: "flutter_liquid_glass_kit",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
      ]
    ),
  ]
)
