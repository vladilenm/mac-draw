import AppKit
import Combine
import DrawingCore

final class CanvasView: NSView, NSTextFieldDelegate {
    let state: AppState
    let displayID: UInt32
    private var subscriptions = Set<AnyCancellable>()
    private var draft: Stroke?
    private var erasing: [Stroke]?
    private var textField: NSTextField?
    private var textDraft: Stroke?
    private var tracking: NSTrackingArea?
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    init(state: AppState, displayID: UInt32, frame: CGRect) {
        self.state = state; self.displayID = displayID
        super.init(frame: frame)
        state.$history.sink { [weak self] history in
            guard let self else { return }
            self.needsDisplay = true
            self.setAccessibilityValue("Объектов на экране: \(history.strokes.filter { $0.displayID == self.displayID }.count)")
        }.store(in: &subscriptions)
        state.$tool.sink { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.window?.invalidateCursorRects(for: self)
            }
        }.store(in: &subscriptions)
        setAccessibilityLabel("Холст для рисования")
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(dirtyRect)
        for stroke in (erasing ?? state.history.strokes) where stroke.displayID == displayID {
            DrawingRenderer.draw(stroke, in: context)
        }
        if let draft { DrawingRenderer.draw(draft, in: context) }
    }

    override func resetCursorRects() {
        let cursor: NSCursor = state.tool == .text ? .iBeam : .crosshair
        addCursorRect(bounds, cursor: cursor)
    }

    override func mouseDown(with event: NSEvent) {
        guard !state.isCursorMode else { return }
        finishEditing()
        window?.makeKey()
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        if state.tool == .text { beginText(at: point); return }
        if state.tool == .eraser {
            erasing = state.history.strokes
            erase(at: point)
            return
        }
        draft = Stroke(tool: state.tool, color: state.color, width: state.width,
                       points: [point], displayID: displayID)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if erasing != nil { erase(at: point); return }
        guard var stroke = draft, let first = stroke.points.first else { return }
        if stroke.tool == .pen {
            if let last = stroke.points.last, hypot(point.x - last.x, point.y - last.y) < 0.5 { return }
            stroke.points.append(point)
        } else {
            let end = event.modifierFlags.contains(.shift) ? Geometry.constrained(point, from: first, tool: stroke.tool) : point
            stroke.points = [first, end]
        }
        draft = stroke
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if let erasing { state.history.replace(with: erasing); self.erasing = nil }
        if draft != nil { mouseDragged(with: event) }
        if let draft {
            if draft.tool == .pen || draft.rect.width + draft.rect.height > 3 { state.history.add(draft) }
        }
        draft = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if !state.handleKey(event) { super.keyDown(with: event) }
    }

    private func erase(at point: CGPoint) {
        erasing?.removeAll { $0.displayID == displayID && $0.hits(point) }
        needsDisplay = true
    }

    private func beginText(at point: CGPoint) {
        let origin = CGPoint(x: min(max(point.x, 4), max(4, bounds.width - 160)),
                             y: min(max(point.y, 4), max(4, bounds.height - 65)))
        let stroke = Stroke(tool: .text, color: state.color, width: state.width, points: [origin], displayID: displayID)
        textDraft = stroke
        let field = NSTextField(frame: CGRect(x: origin.x, y: origin.y, width: min(600, bounds.width - origin.x - 8), height: 60))
        field.font = DrawingRenderer.textAttributes(for: stroke)[.font] as? NSFont
        field.textColor = state.color.nsColor
        field.backgroundColor = NSColor.black.withAlphaComponent(0.72)
        field.isBordered = false
        field.focusRingType = .none
        field.placeholderAttributedString = NSAttributedString(string: "Текст…", attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.4)])
        field.delegate = self
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.setAccessibilityLabel("Текст на экране")
        addSubview(field)
        textField = field
        window?.makeFirstResponder(field)
    }

    func finishEditing(commit: Bool = true) {
        if let field = textField, var stroke = textDraft {
            textField = nil; textDraft = nil
            let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            field.delegate = nil
            field.removeFromSuperview()
            if commit && !text.isEmpty {
                stroke.text = text
                stroke.textSize = (text as NSString).size(withAttributes: DrawingRenderer.textAttributes(for: stroke))
                state.history.add(stroke)
            }
            window?.makeFirstResponder(self)
        }
        // Complete an interrupted gesture before hiding or changing input modes.
        if let erasing { state.history.replace(with: erasing); self.erasing = nil }
        if let draft, draft.tool == .pen || draft.rect.width + draft.rect.height > 3 { state.history.add(draft) }
        draft = nil
        needsDisplay = true
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) { finishEditing(); return true }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            finishEditing(commit: false)
            state.clearAndHide()
            return true
        }
        if commandSelector == #selector(NSResponder.insertTab(_:)) { finishEditing(); state.toggleCursor(); return true }
        return false
    }
}
