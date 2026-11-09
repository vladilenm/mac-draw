import AppKit

let directory = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                     isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let context = NSGraphicsContext.current!.cgContext
        context.scaleBy(x: CGFloat(pixels) / 512, y: CGFloat(pixels) / 512)
        let bounds = CGRect(x: 20, y: 20, width: 472, height: 472)
        NSColor(srgbRed: 0.075, green: 0.09, blue: 0.12, alpha: 1).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 106, yRadius: 106).fill()
        NSColor.white.withAlphaComponent(0.12).setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 104, yRadius: 104)
        border.lineWidth = 3; border.stroke()
        let color = NSColor(srgbRed: 0.08, green: 0.79, blue: 0.97, alpha: 1)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(24); context.setLineCap(.round); context.setLineJoin(.round)
        context.move(to: CGPoint(x: 118, y: 155))
        context.addCurve(to: CGPoint(x: 278, y: 326), control1: CGPoint(x: 118, y: 344), control2: CGPoint(x: 255, y: 120))
        context.addLine(to: CGPoint(x: 377, y: 352))
        context.move(to: CGPoint(x: 315, y: 381)); context.addLine(to: CGPoint(x: 377, y: 352)); context.addLine(to: CGPoint(x: 347, y: 292))
        context.strokePath()
        color.setFill()
        NSBezierPath(ovalIn: CGRect(x: 106, y: 109, width: 24, height: 24)).fill()
        NSGraphicsContext.restoreGraphicsState()
        let data = bitmap.representation(using: .png, properties: [:])!
        let suffix = scale == 2 ? "@2x" : ""
        try data.write(to: URL(fileURLWithPath: "\(directory)/icon_\(size)x\(size)\(suffix).png"))
    }
}

// ICNS is a length-prefixed container; modern entries contain the PNG verbatim.
func bigEndianData(_ number: UInt32) -> Data {
    var value = number.bigEndian
    return withUnsafeBytes(of: &value) { Data($0) }
}
var entries = Data()
for (type, filename) in [("icp4", "icon_16x16.png"), ("icp5", "icon_32x32.png"),
                         ("icp6", "icon_32x32@2x.png"), ("ic07", "icon_128x128.png"),
                         ("ic08", "icon_256x256.png"), ("ic09", "icon_512x512.png"),
                         ("ic10", "icon_512x512@2x.png")] {
    let png = try Data(contentsOf: URL(fileURLWithPath: "\(directory)/\(filename)"))
    entries.append(Data(type.utf8))
    entries.append(bigEndianData(UInt32(png.count + 8)))
    entries.append(png)
}
var icon = Data("icns".utf8)
icon.append(bigEndianData(UInt32(entries.count + 8)))
icon.append(entries)
try icon.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
