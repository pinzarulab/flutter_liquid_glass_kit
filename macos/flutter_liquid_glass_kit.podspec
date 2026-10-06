Pod::Spec.new do |s|
  s.name             = 'flutter_liquid_glass_kit'
  s.version          = '1.5.0'
  s.summary          = 'Native Liquid Glass surfaces for Flutter on macOS.'
  s.description      = <<-DESC
Native SwiftUI Liquid Glass surfaces and grouped page hosts for Flutter on macOS.
                       DESC
  s.homepage         = 'https://github.com/pinzarulab/flutter_liquid_glass_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Pinzaru Lab'
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_liquid_glass_kit/Sources/flutter_liquid_glass_kit/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '12.0'
  s.swift_version = '5.9'
end
