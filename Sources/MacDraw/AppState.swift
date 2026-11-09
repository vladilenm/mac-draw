import AppKit
import SwiftUI
import DrawingCore

final class AppState: ObservableObject {
    @Published var tool: DrawingTool = .pen
    @Published var color: InkColor = InkColor(rawValue: UserDefaults.standard.string(forKey: "inkColor") ?? "") ?? .cyan {
        didSet { UserDefaults.standard.set(color.rawValue, forKey: "inkColor") }
    }
    @Published var width: CGFloat = {
        let saved = UserDefaults.standard.double(forKey: "inkWidth")
        return [2.5, 4.5, 8.0].contains(saved) ? saved : 4.5
    }() {
        didSet { UserDefaults.standard.set(Double(width), forKey: "inkWidth") }
    }
    @Published var history = DrawingHistory()
    @Published var isVisible = false
    @Published var isCursorMode = false
    @Published var hotKeyAvailable = true
    var onHide: (() -> Void)?
    var onModeChange: (() -> Void)?
    var onHelp: (() -> Void)?
    var onFinishEditing: (() -> Void)?
    var onFocusToolbar: (() -> Void)?

    func select(_ tool: DrawingTool) {
        onFinishEditing?()
        self.tool = tool
        isCursorMode = false
        onModeChange?()
    }
    func toggleCursor() {
        onFinishEditing?()
        isCursorMode.toggle()
        onModeChange?()
    }
    func undo() { onFinishEditing?(); history.undo() }
    func redo() { onFinishEditing?(); history.redo() }
    func clear() { onFinishEditing?(); history.clear() }
    func clearAndHide() {
        clear()
        onHide?()
    }

    func handleKey(_ event: NSEvent) -> Bool {
        let command = event.modifierFlags.contains(.command)
        if command {
            if event.keyCode == 6 {
                event.modifierFlags.contains(.shift) ? redo() : undo()
                return true
            }
            if event.keyCode == 51 { clear(); return true }
            return false
        }
        guard !event.modifierFlags.contains(.control), !event.modifierFlags.contains(.option) else { return false }
        switch event.keyCode {
        case 97: onFocusToolbar?()
        case 53: clearAndHide()
        case 48: toggleCursor()
        case 35: select(.pen)
        case 0: select(.arrow)
        case 37: select(.line)
        case 15: select(.rectangle)
        case 31: select(.ellipse)
        case 17: select(.text)
        case 14: select(.eraser)
        case 18: color = .cyan
        case 19: color = .pink
        case 20: color = .green
        case 21: color = .yellow
        case 23: color = .purple
        case 22: color = .white
        case 33: width = width > 4.5 ? 4.5 : 2.5
        case 30: width = width < 4.5 ? 4.5 : 8
        default: return false
        }
        return true
    }
}

extension InkColor {
    var nsColor: NSColor {
        let (r, g, b) = rgb
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
    var swiftUIColor: Color { Color(nsColor: nsColor) }
    var title: String {
        switch self {
        case .cyan: return "Голубой"
        case .pink: return "Розовый"
        case .green: return "Зелёный"
        case .yellow: return "Жёлтый"
        case .purple: return "Фиолетовый"
        case .white: return "Белый"
        }
    }
}

extension DrawingTool {
    var symbol: String {
        switch self {
        case .pen: return "pencil.tip"
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .text: return "textformat"
        case .eraser: return "eraser"
        }
    }
    var title: String {
        switch self {
        case .pen: return "Перо"
        case .arrow: return "Стрелка"
        case .line: return "Линия"
        case .rectangle: return "Прямоугольник"
        case .ellipse: return "Овал"
        case .text: return "Текст"
        case .eraser: return "Ластик"
        }
    }
    var key: String {
        switch self {
        case .pen: return "P"
        case .arrow: return "A"
        case .line: return "L"
        case .rectangle: return "R"
        case .ellipse: return "O"
        case .text: return "T"
        case .eraser: return "E"
        }
    }
}
