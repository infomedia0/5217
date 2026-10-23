import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: TimerModel!
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private var toggleMenu: NSMenuItem!
    private var alertPanel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        model = TimerModel()
        makeMenus()
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 785), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "5217"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(calibratedRed: 0.075, green: 0.09, blue: 0.085, alpha: 1)
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: TimerView(model: model, sounds: model.sounds))
        model.onLayoutChange = { [weak self] in self?.resizeWindow() }
        window.center()
        window.setFrameAutosaveName("5217-main-window")
        model.onUpdate = { [weak self] in self?.updateMenu() }
        model.onShow = { [weak self] in self?.showWindow() }
        model.onSilenceAlert = { [weak self] in self?.alertPanel?.close() }
        model.onAlert = { [weak self] phase in self?.showAlert(completed: phase) }
        updateMenu()
        showWindow()
    }

    private func resizeWindow() {
        guard let window, let content = window.contentView else { return }
        let difference = model.windowHeight - content.frame.height
        guard abs(difference) > 0.5 else { return }
        var frame = window.frame
        frame.origin.y -= difference // Keep the top edge in place while changing height.
        frame.size.height += difference
        window.setFrame(frame, display: true, animate: false)
    }

    private func makeMenus() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About 5217", action: #selector(about), keyEquivalent: "")
        appMenu.addItem(item("Settings…", action: #selector(showSettings), key: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide 5217", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit 5217", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)
        let timerItem = NSMenuItem()
        timerItem.title = "Timer"
        let timerMenu = NSMenu(title: "Timer")
        timerMenu.addItem(item("Start / Pause", action: #selector(toggle), key: "p"))
        timerMenu.addItem(item("Reset Timer", action: #selector(reset), key: "r"))
        timerMenu.addItem(item("Skip to Next Phase", action: #selector(skip), key: String(UnicodeScalar(NSRightArrowFunctionKey)!)))
        timerMenu.addItem(.separator())
        timerMenu.addItem(item("Next Quote", action: #selector(nextQuote), key: "n"))
        timerMenu.addItem(item("Update Online Quotes", action: #selector(updateOnlineQuotes)))
        timerMenu.addItem(item("Test Alert & Chime", action: #selector(testSound)))
        timerMenu.addItem(item("Show 5217", action: #selector(showWindow), key: "0"))
        timerItem.submenu = timerMenu
        main.addItem(timerItem)
        NSApp.mainMenu = main

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let statusMenu = NSMenu()
        statusMenu.addItem(item("Open 5217", action: #selector(showWindow)))
        statusMenu.addItem(item("Settings…", action: #selector(showSettings)))
        statusMenu.addItem(.separator())
        toggleMenu = item("Start Focus", action: #selector(toggle))
        statusMenu.addItem(toggleMenu)
        statusMenu.addItem(item("Reset Timer", action: #selector(reset)))
        statusMenu.addItem(item("Skip to Next Phase", action: #selector(skip)))
        statusMenu.addItem(.separator())
        statusMenu.addItem(withTitle: "Quit 5217", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = statusMenu
    }

    private func item(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func updateMenu() {
        let symbol = model.engine.phase == .focus ? "◉" : "☕︎"
        statusItem.button?.title = "\(symbol) \(model.clockText)"
        statusItem.button?.toolTip = "5217 · \(model.engine.phase.title)\(model.engine.isRunning ? "" : " · Paused")"
        statusItem.button?.setAccessibilityLabel("5217 \(model.engine.phase.title), \(model.clockText)")
        toggleMenu.title = model.engine.isRunning ? "Pause" : "\(model.hasStarted ? "Resume" : "Start") \(model.engine.phase.title)"
    }

    @objc func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        model.refreshNotificationStatus()
    }
    @objc private func showSettings() { showWindow(); model.screen = .settings }
    @objc private func toggle() { model.toggle() }
    @objc private func reset() { model.reset() }
    @objc private func skip() { model.skip() }
    @objc private func nextQuote() { model.nextQuote() }
    @objc private func updateOnlineQuotes() { model.refreshOnlineQuotes() }
    @objc private func testSound() { model.testAlert() }
    private func showAlert(completed: Phase) {
        alertPanel?.close()
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 132), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: TransitionAlert(completed: completed) { [weak panel] in panel?.close() })
        if let frame = NSScreen.main?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: frame.maxX - 380, y: frame.maxY - 152))
        }
        alertPanel = panel
        panel.orderFrontRegardless()
        NSApp.requestUserAttention(.informationalRequest)
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak panel] in panel?.close() }
    }
    @objc private func about() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "5217", .applicationVersion: AppVersion.current,
            .credits: NSAttributedString(string: "52 minutes of focus. 17 minutes to reset.\nA quiet rhythm for your day.\n\nMade for Mac. Timer history stays on this device.")
        ])
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showWindow(); return true }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { model.shutdown() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
