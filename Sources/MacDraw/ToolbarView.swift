import SwiftUI
import AppKit
import DrawingCore

struct ToolbarView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                DragHandle().frame(width: 15, height: 36).help("Перетащите панель")
                HStack(spacing: 3) {
                    toolButton("cursorarrow", label: "Курсор · Tab", active: state.isCursorMode) { state.toggleCursor() }
                    ForEach(DrawingTool.allCases, id: \.self) { tool in
                        toolButton(tool.symbol, label: "\(tool.title) · \(tool.key)", active: !state.isCursorMode && state.tool == tool) { state.select(tool) }
                    }
                }
                separator
                HStack(spacing: 5) {
                    ForEach(Array(InkColor.allCases.enumerated()), id: \.element) { index, color in
                        Button { state.color = color } label: {
                            Circle().fill(color.swiftUIColor)
                                .frame(width: 17, height: 17)
                                .padding(4)
                                .overlay(Circle().stroke(state.color == color ? color.swiftUIColor : .clear, lineWidth: 1.5))
                                .frame(width: 26, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("\(color.title) · \(index + 1)")
                        .accessibilityLabel(color.title)
                        .accessibilityAddTraits(state.color == color ? .isSelected : [])
                    }
                }
                separator
                HStack(spacing: 2) {
                    ForEach([2.5, 4.5, 8.0], id: \.self) { width in
                        Button { state.width = width } label: {
                            Circle().fill(state.width == width ? Color.white : Color.white.opacity(0.45))
                                .frame(width: width + 1, height: width + 1)
                                .frame(width: 25, height: 32)
                                .background(state.width == width ? Color.white.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 7))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Толщина \(Int(width)) · [ / ]")
                        .accessibilityLabel(width == 2.5 ? "Тонкая линия" : width == 4.5 ? "Средняя линия" : "Толстая линия")
                    }
                }
                separator
                HStack(spacing: 2) {
                    toolButton("arrow.uturn.backward", label: "Отменить · ⌘Z", enabled: state.history.canUndo) { state.undo() }
                    toolButton("arrow.uturn.forward", label: "Повторить · ⇧⌘Z", enabled: state.history.canRedo) { state.redo() }
                    toolButton("trash", label: "Очистить всё · ⌘⌫", enabled: !state.history.strokes.isEmpty) { state.clear() }
                }
                separator
                toolButton("xmark", label: "Скрыть без очистки · ⌃⌥D") { state.onHide?() }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Rectangle().fill(.white.opacity(0.07)).frame(height: 1)
            HStack(spacing: 6) {
                Circle().fill(state.isCursorMode ? Color.gray : state.color.swiftUIColor).frame(width: 5, height: 5)
                Text(state.isCursorMode ? "Курсор · окна доступны для кликов" : "\(state.tool.title) · рисуйте поверх экрана")
                Spacer(minLength: 16)
                Text(state.isCursorMode ? "Выберите инструмент, чтобы рисовать" : "⇧ ровные фигуры    ⌃⌥D показать / скрыть")
                    .foregroundStyle(.white.opacity(0.4))
                Button { state.onHelp?() } label: {
                    Image(systemName: "questionmark.circle").font(.system(size: 12))
                }.buttonStyle(.plain).help("Как пользоваться Mac Draw").accessibilityLabel("Помощь")
            }
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(.white.opacity(0.65))
            .padding(.horizontal, 16)
            .frame(height: 27)
        }
        .background(Color(red: 0.085, green: 0.095, blue: 0.115).opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(.white.opacity(0.14), lineWidth: 1))
        .fixedSize()
        .environment(\.colorScheme, .dark)
    }

    private var separator: some View {
        Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 23).padding(.horizontal, 3)
    }

    private func toolButton(_ symbol: String, label: String, active: Bool = false,
                            enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(active ? state.color.swiftUIColor : Color.white.opacity(enabled ? 0.8 : 0.2))
                .frame(width: 33, height: 34)
                .background(active ? state.color.swiftUIColor.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(ToolPressStyle())
        .disabled(!enabled)
        .help(label)
        .accessibilityLabel(label)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

private struct ToolPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(configuration.isPressed ? Color.white.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> HandleView { HandleView() }
    func updateNSView(_ nsView: HandleView, context: Context) {}

    final class HandleView: NSView {
        override func draw(_ dirtyRect: NSRect) {
            NSColor.white.withAlphaComponent(0.3).setFill()
            for x in [5.0, 10.0] {
                for y in [12.0, 18.0, 24.0] { NSBezierPath(ovalIn: CGRect(x: x, y: y, width: 2, height: 2)).fill() }
            }
        }
        override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
            guard let window, let screen = window.screen else { return }
            var origin = window.frame.origin
            origin.x = max(screen.visibleFrame.minX, min(origin.x, screen.visibleFrame.maxX - window.frame.width))
            origin.y = max(screen.visibleFrame.minY, min(origin.y, screen.visibleFrame.maxY - window.frame.height))
            window.setFrameOrigin(origin)
        }
    }
}
