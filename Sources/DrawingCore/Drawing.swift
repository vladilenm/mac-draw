import Foundation
import CoreGraphics

public enum DrawingTool: String, CaseIterable, Sendable {
    case pen, arrow, line, rectangle, ellipse, text, eraser
}

public enum InkColor: String, CaseIterable, Sendable {
    case cyan, pink, green, yellow, purple, white
    public var rgb: (Double, Double, Double) {
        switch self {
        case .cyan: return (0.08, 0.79, 0.97)
        case .pink: return (1, 0.28, 0.49)
        case .green: return (0.43, 0.93, 0.37)
        case .yellow: return (1, 0.85, 0.25)
        case .purple: return (0.73, 0.49, 1)
        case .white: return (1, 1, 1)
        }
    }
}

public struct Stroke: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var tool: DrawingTool
    public var color: InkColor
    public var width: CGFloat
    public var points: [CGPoint]
    public var text: String
    public var textSize: CGSize
    public var displayID: UInt32

    public init(id: UUID = UUID(), tool: DrawingTool, color: InkColor = .cyan,
                width: CGFloat = 4, points: [CGPoint], text: String = "",
                textSize: CGSize = .zero, displayID: UInt32 = 0) {
        self.id = id; self.tool = tool; self.color = color; self.width = width
        self.points = points; self.text = text; self.textSize = textSize
        self.displayID = displayID
    }

    public var rect: CGRect {
        guard let start = points.first, let end = points.last else { return .zero }
        return CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                      width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    public var arrowWings: [CGPoint] {
        guard let start = points.first, let end = points.last else { return [] }
        let distance = hypot(end.x - start.x, end.y - start.y)
        guard distance > 0.01 else { return [] }
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = min(max(14, width * 3.5), distance * 0.65)
        return [-CGFloat.pi / 6, CGFloat.pi / 6].map {
            CGPoint(x: end.x - length * cos(angle + $0), y: end.y - length * sin(angle + $0))
        }
    }

    public func hits(_ point: CGPoint, tolerance: CGFloat = 9) -> Bool {
        guard let start = points.first, let end = points.last else { return false }
        let radius = tolerance + width / 2
        switch tool {
        case .text:
            return CGRect(origin: start, size: textSize).insetBy(dx: -tolerance, dy: -tolerance).contains(point)
        case .rectangle:
            let r = rect
            let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                           CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
            return (0..<4).contains { Geometry.distance(point, to: corners[$0], corners[($0 + 1) % 4]) <= radius }
        case .ellipse:
            let r = rect
            if r.width < 1 || r.height < 1 { return Geometry.distance(point, to: start, end) <= radius }
            let samples = (0...96).map { index -> CGPoint in
                let angle = CGFloat(index) * .pi * 2 / 96
                return CGPoint(x: r.midX + r.width / 2 * cos(angle), y: r.midY + r.height / 2 * sin(angle))
            }
            return zip(samples, samples.dropFirst()).contains { Geometry.distance(point, to: $0, $1) <= radius }
        case .arrow:
            return Geometry.distance(point, to: start, end) <= radius || arrowWings.contains {
                Geometry.distance(point, to: $0, end) <= radius
            }
        case .pen:
            if points.count == 1 { return hypot(point.x - start.x, point.y - start.y) <= radius }
            return zip(points, points.dropFirst()).contains { Geometry.distance(point, to: $0, $1) <= radius }
        default:
            return Geometry.distance(point, to: start, end) <= radius
        }
    }
}

public enum Geometry {
    public static func distance(_ p: CGPoint, to a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let squaredLength = dx * dx + dy * dy
        guard squaredLength > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / squaredLength))
        return hypot(p.x - a.x - t * dx, p.y - a.y - t * dy)
    }

    public static func constrained(_ end: CGPoint, from start: CGPoint, tool: DrawingTool) -> CGPoint {
        let dx = end.x - start.x, dy = end.y - start.y
        if tool == .rectangle || tool == .ellipse {
            let size = max(abs(dx), abs(dy))
            return CGPoint(x: start.x + (dx < 0 ? -size : size), y: start.y + (dy < 0 ? -size : size))
        }
        if tool == .arrow || tool == .line {
            let angle = (atan2(dy, dx) / (.pi / 4)).rounded() * (.pi / 4)
            let length = hypot(dx, dy)
            return CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length)
        }
        return end
    }
}

public struct DrawingHistory {
    public private(set) var strokes: [Stroke] = []
    private var past: [[Stroke]] = []
    private var future: [[Stroke]] = []
    public var canUndo: Bool { !past.isEmpty }
    public var canRedo: Bool { !future.isEmpty }
    public init() {}

    public mutating func replace(with next: [Stroke]) {
        guard next != strokes else { return }
        past.append(strokes)
        if past.count > 100 { past.removeFirst() }
        strokes = next
        future.removeAll()
    }
    public mutating func add(_ stroke: Stroke) { replace(with: strokes + [stroke]) }
    public mutating func clear() { replace(with: []) }
    public mutating func undo() {
        guard let previous = past.popLast() else { return }
        future.append(strokes); strokes = previous
    }
    public mutating func redo() {
        guard let next = future.popLast() else { return }
        past.append(strokes); strokes = next
    }
}
