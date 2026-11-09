import AppKit

// Inspect the real window configuration without showing windows or taking focus.
func runWindowChecks() -> Bool {
    _ = NSApplication.shared
    let makePanel = {
        NSPanel(contentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
                styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    }
    let canvas = makePanel()
    let toolbar = makePanel()
    OverlayController.configure(canvas, level: NSWindow.Level.statusBar.rawValue + 1)
    OverlayController.configure(toolbar, level: NSWindow.Level.statusBar.rawValue + 2)
    let canvases = [canvas]
    guard canvases.allSatisfy({ toolbar.level.rawValue > $0.level.rawValue }) else {
        print("FAIL: toolbar level \(toolbar.level.rawValue) must stay above canvas levels \(canvases.map { $0.level.rawValue })")
        return false
    }
    guard canvases.allSatisfy({ $0.level.rawValue > NSWindow.Level.statusBar.rawValue }) else {
        print("FAIL: canvas lost its configured overlay level")
        return false
    }
    print("PASS: toolbar level \(toolbar.level.rawValue) stays above canvas levels \(canvases.map { $0.level.rawValue })")
    return true
}
