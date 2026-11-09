import Foundation
import CoreGraphics
import DrawingCore

enum CheckFailure: Error { case failed(Int) }
func check(_ condition: @autoclosure () -> Bool, line: Int = #line) {
    guard condition() else { fatalError("Check failed at line \(line)") }
}
func checkEqual<T: Equatable>(_ a: T, _ b: T, line: Int = #line) { check(a == b, line: line) }
func checkNear(_ a: CGFloat, _ b: CGFloat, accuracy: CGFloat, line: Int = #line) { check(abs(a - b) <= accuracy, line: line) }

@main
struct DrawingTests {
    static func main() {
        let suite = DrawingTests()
        suite.testHistoryRestoresClearAndInvalidatesRedoAfterNewStroke()
        suite.testEmptyClearDoesNotCreateUndoEntry()
        suite.testEraserGestureCanBeUndoneAsSingleTransaction()
        suite.testShapeNormalizationAndShiftConstraintForReverseDrag()
        suite.testLineAngleSnappingPreservesLength()
        suite.testArrowWingsAreErasableAndShortArrowsStayBounded()
        suite.testEllipseHitTestingDoesNotEraseThroughEmptyCenter()
        suite.testTextBoundsAndSinglePointStroke()
        print("8 checks passed: history, clear, eraser transaction, shape constraints, angle snapping, arrow geometry, ellipse erasure, text bounds")
    }
    func testHistoryRestoresClearAndInvalidatesRedoAfterNewStroke() {
        var h = DrawingHistory()
        let a = Stroke(tool: .pen, points: [.zero, CGPoint(x: 30, y: 40)])
        let b = Stroke(tool: .arrow, points: [.zero, CGPoint(x: 100, y: 20)])
        h.add(a); h.add(b); h.clear()
        check(h.strokes.isEmpty)
        h.undo(); checkEqual(h.strokes, [a, b])
        h.redo(); check(h.strokes.isEmpty)
        h.undo(); h.undo(); checkEqual(h.strokes, [a])
        h.add(b); check(!h.canRedo)
    }

    func testEmptyClearDoesNotCreateUndoEntry() {
        var h = DrawingHistory()
        h.clear(); h.undo(); h.redo()
        check(!h.canUndo); check(!h.canRedo)
    }

    func testEraserGestureCanBeUndoneAsSingleTransaction() {
        var h = DrawingHistory()
        let a = Stroke(tool: .pen, points: [.zero])
        let b = Stroke(tool: .pen, points: [CGPoint(x: 100, y: 100)])
        h.add(a); h.add(b)
        h.replace(with: [])
        h.undo(); checkEqual(h.strokes, [a, b])
    }

    func testShapeNormalizationAndShiftConstraintForReverseDrag() {
        let origin = CGPoint(x: 200, y: 200)
        let end = Geometry.constrained(CGPoint(x: 100, y: 160), from: origin, tool: .rectangle)
        checkEqual(end, CGPoint(x: 100, y: 100))
        let s = Stroke(tool: .rectangle, points: [origin, end])
        checkEqual(s.rect, CGRect(x: 100, y: 100, width: 100, height: 100))
        check(s.hits(CGPoint(x: 100, y: 150)))
        check(!s.hits(CGPoint(x: 150, y: 150)))
    }

    func testLineAngleSnappingPreservesLength() {
        let end = Geometry.constrained(CGPoint(x: 100, y: 8), from: .zero, tool: .arrow)
        checkNear(end.y, 0, accuracy: 0.001)
        checkNear(end.x, hypot(100, 8), accuracy: 0.001)
    }

    func testArrowWingsAreErasableAndShortArrowsStayBounded() {
        let s = Stroke(tool: .arrow, points: [.zero, CGPoint(x: 100, y: 0)])
        check(s.hits(s.arrowWings[0], tolerance: 1))
        check(!s.hits(CGPoint(x: 50, y: 40), tolerance: 1))
        let tiny = Stroke(tool: .arrow, points: [.zero, CGPoint(x: 2, y: 0)])
        check(tiny.arrowWings.allSatisfy { $0.x >= 0 })
        check(Stroke(tool: .arrow, points: [.zero, .zero]).arrowWings.isEmpty)
    }

    func testEllipseHitTestingDoesNotEraseThroughEmptyCenter() {
        let s = Stroke(tool: .ellipse, points: [.zero, CGPoint(x: 200, y: 100)])
        check(s.hits(CGPoint(x: 100, y: 0)))
        check(s.hits(CGPoint(x: 200, y: 50)))
        check(!s.hits(CGPoint(x: 100, y: 50)))
    }

    func testTextBoundsAndSinglePointStroke() {
        let s = Stroke(tool: .text, points: [CGPoint(x: 10, y: 10)], text: "Hello", textSize: CGSize(width: 80, height: 30))
        check(s.hits(CGPoint(x: 80, y: 25), tolerance: 0))
        check(!s.hits(CGPoint(x: 200, y: 25)))
        check(Stroke(tool: .pen, points: [.zero]).hits(.zero))
    }
}
