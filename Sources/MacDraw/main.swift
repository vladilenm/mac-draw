import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let state = AppState()
    private var overlay: OverlayController!
    private var hotKey: GlobalHotKey?
    private var statusItem: NSStatusItem!
    private var welcome: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMainMenu()
        overlay = OverlayController(state: state)
        state.onHelp = { [weak self] in self?.showWelcome() }
        hotKey = GlobalHotKey { [weak self] in self?.toggleDrawing() }
        state.hotKeyAvailable = hotKey?.isRegistered ?? false
        configureStatusItem()
        if !UserDefaults.standard.bool(forKey: "hasSeenWelcome") || !state.hotKeyAvailable {
            showWelcome()
        }
    }

    private func configureMainMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "О Mac Draw", action: #selector(showWelcome), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Завершить Mac Draw", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Правка")
        for (title, selector, key) in [("Вырезать", #selector(NSText.cut(_:)), "x"), ("Копировать", #selector(NSText.copy(_:)), "c"),
                                       ("Вставить", #selector(NSText.paste(_:)), "v"), ("Выбрать всё", #selector(NSText.selectAll(_:)), "a")] {
            editMenu.addItem(withTitle: title, action: selector, keyEquivalent: key)
        }
        editItem.submenu = editMenu; menu.addItem(editItem)
        NSApp.mainMenu = menu
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "pencil.tip.crop.circle", accessibilityDescription: "Mac Draw")
        statusItem.button?.toolTip = "Mac Draw · ⌃⌥D"
        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Показать / скрыть рисунки    ⌃⌥D", action: #selector(toggleDrawing), keyEquivalent: "")
        toggle.target = self; menu.addItem(toggle)
        let clear = NSMenuItem(title: "Очистить рисунки", action: #selector(clearDrawing), keyEquivalent: "")
        clear.target = self; menu.addItem(clear)
        menu.addItem(.separator())
        let help = NSMenuItem(title: "Как пользоваться Mac Draw", action: #selector(showWelcome), keyEquivalent: "")
        help.target = self; menu.addItem(help)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Завершить Mac Draw", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func toggleDrawing() {
        welcome?.orderOut(nil)
        overlay.toggle()
    }
    @objc private func clearDrawing() { state.clear() }

    @objc private func showWelcome() {
        if state.isVisible { overlay.hide() }
        if welcome == nil {
            let host = NSHostingView(rootView: WelcomeView(state: state) { [weak self] in
                UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                self?.welcome?.orderOut(nil)
                self?.overlay.show()
            })
            let window = NSWindow(contentRect: CGRect(origin: .zero, size: host.fittingSize), styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
            window.title = "Mac Draw"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.backgroundColor = NSColor(srgbRed: 0.07, green: 0.08, blue: 0.1, alpha: 1)
            window.appearance = NSAppearance(named: .darkAqua)
            window.contentView = host
            window.center()
            welcome = window
        }
        NSApp.activate(ignoringOtherApps: true)
        welcome?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWelcome()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) { overlay?.hide() }
}

if CommandLine.arguments.contains("--check-rendering") {
    runRenderingChecks()
    exit(0)
}
if CommandLine.arguments.contains("--check-windows") {
    exit(runWindowChecks() ? 0 : 1)
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
