#!/usr/bin/env swift
import AppKit
import Foundation

/// Render the traced tart vector and compile the official macOS icon resources.
/// Requires Xcode's actool. No network, Node, signing or publishing is performed.
let root = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
    .deletingLastPathComponent().deletingLastPathComponent()
let design = root.appendingPathComponent("design")
let resources = root.appendingPathComponent("Resources")
let iconBundle = design.appendingPathComponent("AppIcon.icon")
let source = design.appendingPathComponent("pastel-tart.svg")
guard let vector = NSImage(contentsOf: source) else { fatalError("Generate design/pastel-tart.svg first") }
let size = NSSize(width: 1024, height: 1024)

func png(background: Bool) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    if background {
        NSColor(srgbRed: 1, green: 247.0 / 255, blue: 229.0 / 255, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 225, yRadius: 225).fill()
    }
    vector.draw(in: NSRect(origin: .zero, size: size))
    return bitmap.representation(using: .png, properties: [:])!
}

try FileManager.default.createDirectory(at: iconBundle.appendingPathComponent("Assets"), withIntermediateDirectories: true)
try png(background: false).write(to: iconBundle.appendingPathComponent("Assets/foreground.png"))
let configuration: [String: Any] = [
    "groups": [["name": "Tart", "layers": [["image-name": "foreground.png", "name": "Tart", "glass": false]],
                "specular": false, "blur-material": 0, "translucency": ["enabled": false, "value": 0]]],
    "supported-platforms": ["squares": "shared", "circles": ["watchOS"]],
    "fill-specializations": [
        ["value": ["solid": "srgb:1.00000,0.96863,0.89804,1.00000"]],
        ["appearance": "dark", "value": ["solid": "srgb:0.20392,0.16863,0.13725,1.00000"]]
    ]
]
try JSONSerialization.data(withJSONObject: configuration, options: [.prettyPrinted, .sortedKeys])
    .write(to: iconBundle.appendingPathComponent("icon.json"))
let output = root.appendingPathComponent("work/pastel-brand-validation/actool")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
process.arguments = ["actool", iconBundle.path, "--compile", output.path, "--platform", "macosx",
    "--minimum-deployment-target", "14.0", "--app-icon", "AppIcon",
    "--output-partial-info-plist", output.appendingPathComponent("info.plist").path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { fatalError("actool failed; existing Resources were kept") }
for name in ["Assets.car", "AppIcon.icns"] {
    let data = try Data(contentsOf: output.appendingPathComponent(name))
    guard !data.isEmpty else { fatalError("Empty icon resource: \(name)") }
    try data.write(to: resources.appendingPathComponent(name), options: .atomic)
}
let preview = png(background: true)
try preview.write(to: resources.appendingPathComponent("AppIcon.png"), options: .atomic)
try preview.write(to: design.appendingPathComponent("pastel-app-preview.png"), options: .atomic)
print("Generated AppIcon.icns, Assets.car and Pastel it！ previews from pastel-tart.svg")
