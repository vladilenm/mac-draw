import AppKit
import DrawingCore

enum DrawingRenderer {
    static func textAttributes(for stroke: Stroke) -> [NSAttributedString.Key: Any] {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.55)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        return [.font: NSFont.systemFont(ofSize: 22 + stroke.width * 2, weight: .semibold),
                .foregroundColor: stroke.color.nsColor, .shadow: shadow]
    }

    static func draw(_ stroke: Stroke, in context: CGContext) {
        guard let first = stroke.points.first, let last = stroke.points.last else { return }
        if stroke.tool == .text {
            (stroke.text as NSString).draw(at: first, withAttributes: textAttributes(for: stroke))
            return
        }
        context.saveGState()
        defer { context.restoreGState() }
        context.setStrokeColor(stroke.color.nsColor.cgColor)
        context.setFillColor(stroke.color.nsColor.cgColor)
        context.setLineWidth(stroke.width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setShadow(offset: CGSize(width: 0, height: 1), blur: 2, color: NSColor.black.withAlphaComponent(0.22).cgColor)
        let path = CGMutablePath()
        switch stroke.tool {
        case .pen:
            if stroke.points.count == 1 {
                context.fillEllipse(in: CGRect(x: first.x - stroke.width / 2, y: first.y - stroke.width / 2, width: stroke.width, height: stroke.width))
                return
            }
            path.move(to: first)
            for index in 1..<stroke.points.count {
                let previous = stroke.points[index - 1], current = stroke.points[index]
                let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
                path.addQuadCurve(to: mid, control: previous)
            }
            path.addLine(to: last)
        case .arrow:
            path.move(to: first); path.addLine(to: last)
            for wing in stroke.arrowWings { path.move(to: wing); path.addLine(to: last) }
        case .line:
            path.move(to: first); path.addLine(to: last)
        case .rectangle:
            // A new drag starts with a zero-sized rect. CoreGraphics asserts
            // if a rounded corner is larger than half either dimension.
            let rect = stroke.rect
            if rect.width < 1 || rect.height < 1 {
                path.move(to: first); path.addLine(to: last)
            } else {
                path.addRoundedRect(in: rect, cornerWidth: min(3, rect.width / 2), cornerHeight: min(3, rect.height / 2))
            }
        case .ellipse:
            if stroke.rect.width < 1 || stroke.rect.height < 1 {
                path.move(to: first); path.addLine(to: last)
            } else { path.addEllipse(in: stroke.rect) }
        default: return
        }
        context.addPath(path)
        context.strokePath()
    }
}
