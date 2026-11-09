import AppKit
import DrawingCore

// Exercises the actual AppKit renderer without opening windows.
func runRenderingChecks() {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 256,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    let cases: [[CGPoint]] = [[], [.zero], [.zero, .zero],
                             [CGPoint(x: 20, y: 20), CGPoint(x: 20.1, y: 20.1)],
                             [CGPoint(x: 20, y: 20), CGPoint(x: 20, y: 100)],
                             [CGPoint(x: 160, y: 160), CGPoint(x: 40, y: 40)]]
    var count = 0
    for tool in DrawingTool.allCases where tool != .eraser {
        for points in cases {
            let stroke = Stroke(tool: tool, points: points, text: "Тест")
            DrawingRenderer.draw(stroke, in: context)
            count += 1
        }
    }
    // Confirm the renderer produced actual pixels, not just a successful return.
    let visible = (0..<256).contains { x in
        (0..<256).contains { y in (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5 }
    }
    precondition(visible, "Renderer produced no visible pixels")
    print("\(count) rendering checks passed, including zero-sized and subpixel shapes")
}
