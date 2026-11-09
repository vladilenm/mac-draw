import AppKit
import SwiftUI

private final class CanvasPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class ToolbarPanel: NSPanel {
    var appState: AppState?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func keyDown(with event: NSEvent) {
        if appState?.handleKey(event) != true { super.keyDown(with: event) }
    }
}

final class OverlayController {
    let state: AppState
    private var canvases: [(panel: NSPanel, view: CanvasView)] = []
    private var toolbar: NSPanel!
    private var screenObserver: NSObjectProtocol?
    private var previousApp: NSRunningApplication?

    init(state: AppState) {
        self.state = state
        buildWindows()
        state.onHide = { [weak self] in self?.hide() }
        state.onModeChange = { [weak self] in self?.updateMode() }
        state.onFinishEditing = { [weak self] in self?.finishEditing() }
        state.onFocusToolbar = { [weak self] in
            self?.finishEditing()
            self?.toolbar.makeKeyAndOrderFront(nil)
        }
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.finishEditing()
            self.buildWindows()
            if self.state.isVisible { self.presentWindows(); self.updateMode() }
        }
    }

    static func configure(_ panel: NSPanel, level: Int) {
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // AppKit resets level to .floating when this flag changes.
        // Set it first so the toolbar keeps a higher level than the canvases.
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: level)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
    }

    private func buildWindows() {
        canvases.forEach { $0.panel.orderOut(nil) }
        canvases.removeAll()
        toolbar?.orderOut(nil)
        for screen in NSScreen.screens {
            let panel = CanvasPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            Self.configure(panel, level: NSWindow.Level.statusBar.rawValue + 1)
            panel.title = "Mac Draw — холст"
            let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            let view = CanvasView(state: state, displayID: id, frame: CGRect(origin: .zero, size: screen.frame.size))
            panel.contentView = view
            canvases.append((panel, view))
        }
        let host = NSHostingView(rootView: ToolbarView(state: state))
        let size = host.fittingSize
        let panel = ToolbarPanel(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.appState = state
        Self.configure(panel, level: NSWindow.Level.statusBar.rawValue + 2)
        panel.title = "Mac Draw — инструменты"
        panel.hasShadow = true
        panel.contentView = host
        panel.setContentSize(size)
        toolbar = panel
    }

    func toggle() { state.isVisible ? hide() : show() }

    func show() {
        if !state.isVisible {
            let frontmost = NSWorkspace.shared.frontmostApplication
            if frontmost?.processIdentifier != ProcessInfo.processInfo.processIdentifier { previousApp = frontmost }
        }
        state.isVisible = true
        state.isCursorMode = false
        presentWindows()
        updateMode()
    }

    private func presentWindows() {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        if let screen {
            let area = screen.visibleFrame
            toolbar.setFrameOrigin(CGPoint(x: area.midX - toolbar.frame.width / 2, y: area.maxY - toolbar.frame.height - 16))
        }
        canvases.forEach { $0.panel.orderFrontRegardless() }
        toolbar.orderFrontRegardless()
    }

    func hide() {
        finishEditing()
        state.isVisible = false
        canvases.forEach { $0.panel.orderOut(nil) }
        toolbar.orderOut(nil)
        restorePreviousApp()
    }

    private func updateMode() {
        guard state.isVisible else { return }
        for canvas in canvases {
            canvas.panel.ignoresMouseEvents = state.isCursorMode
            canvas.panel.invalidateCursorRects(for: canvas.view)
        }
        if state.isCursorMode {
            canvases.forEach { $0.panel.resignKey() }
            restorePreviousApp()
        } else {
            let target = canvases.first { NSMouseInRect(NSEvent.mouseLocation, $0.panel.frame, false) } ?? canvases.first
            target?.panel.makeKey()
            if let target { target.panel.makeFirstResponder(target.view) }
        }
        toolbar.orderFrontRegardless()
    }

    private func restorePreviousApp() {
        if NSApp.isActive, let previousApp, !previousApp.isTerminated { previousApp.activate(options: []) }
    }

    func finishEditing() { canvases.forEach { $0.view.finishEditing() } }

    deinit {
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
    }
}
