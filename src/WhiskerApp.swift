import AppKit
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleMenuBar = Self("toggleMenuBar", default: .init(.y, modifiers: [.command, .shift]))
}

enum AutoHideDelay: Int, CaseIterable, Identifiable {
    case disabled = 0
    case fiveSeconds = 5
    case tenSeconds = 10
    case thirtySeconds = 30
    case oneMinute = 60
    case twoMinutes = 120

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .disabled: return "Off"
        case .fiveSeconds: return "5 seconds"
        case .tenSeconds: return "10 seconds"
        case .thirtySeconds: return "30 seconds"
        case .oneMinute: return "1 minute"
        case .twoMinutes: return "2 minutes"
        }
    }

    var timeInterval: TimeInterval? {
        rawValue == 0 ? nil : TimeInterval(rawValue)
    }

    var isEnabled: Bool { self != .disabled }
    static var defaultValue: AutoHideDelay { .disabled }
}

extension Notification.Name {
    static let autoHideSettingsChanged = Notification.Name("WhiskerAutoHideSettingsChanged")
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?
    var isHidden = false
    var autoHideTimer: Timer?
    private var currentAutoHideDelay: AutoHideDelay = .disabled

    let hiddenLength: CGFloat = 10_000
    let hiddenStateKey = "WhiskerIsHidden"
    static let autoHideDelayKey = "WhiskerAutoHideDelay"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupStatusItem()
        setupKeyboardShortcut()
        setupAutoHideObserver()

        isHidden = UserDefaults.standard.bool(forKey: hiddenStateKey)
        let delayRawValue = UserDefaults.standard.integer(forKey: Self.autoHideDelayKey)
        currentAutoHideDelay = AutoHideDelay(rawValue: delayRawValue) ?? .disabled
        updateVisibility()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit Whisker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func setupKeyboardShortcut() {
        KeyboardShortcuts.onKeyUp(for: .toggleMenuBar) { [weak self] in
            DispatchQueue.main.async {
                self?.toggle()
            }
        }
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let icon = NSImage(systemSymbolName: "circlebadge.fill", accessibilityDescription: "Whisker")
            icon?.isTemplate = true
            button.image = icon
            button.target = self
            button.action = #selector(clicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @MainActor @objc func clicked(_ sender: NSStatusBarButton) {
        showContextMenu()
    }

    func toggle() {
        isHidden.toggle()
        UserDefaults.standard.set(isHidden, forKey: hiddenStateKey)
        updateVisibility()
    }

    func updateVisibility() {
        if isHidden {
            cancelAutoHideTimer()
            statusItem.length = hiddenLength
            statusItem.button?.image = nil
        } else {
            statusItem.length = NSStatusItem.variableLength
            let icon = NSImage(systemSymbolName: "circlebadge.fill", accessibilityDescription: "Whisker")
            icon?.isTemplate = true
            statusItem.button?.image = icon
            scheduleAutoHideTimer()
        }
    }

    private func setupAutoHideObserver() {
        NotificationCenter.default.addObserver(
            forName: .autoHideSettingsChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAutoHideSettingsChanged()
            }
        }
    }

    private func handleAutoHideSettingsChanged() {
        let delayRawValue = UserDefaults.standard.integer(forKey: Self.autoHideDelayKey)
        currentAutoHideDelay = AutoHideDelay(rawValue: delayRawValue) ?? .disabled
        if !isHidden {
            scheduleAutoHideTimer()
        }
    }

    private func scheduleAutoHideTimer() {
        cancelAutoHideTimer()

        guard let interval = currentAutoHideDelay.timeInterval else {
            return
        }

        autoHideTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.autoHide()
            }
        }
    }

    private func cancelAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    private func autoHide() {
        guard !isHidden else { return }
        toggle()
    }

    @MainActor func showContextMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: isHidden ? "Show Icons" : "Hide Icons",
            action: #selector(menuToggle),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.setShortcut(for: .toggleMenuBar)
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func menuToggle() {
        toggle()
    }

    @objc func openSettings() {
        showSettingsWindow()
    }

    func showSettingsWindow() {
        if settingsWindow == nil {
            let hostingController = NSHostingController(rootView: SettingsView())
            hostingController.sizingOptions = [.preferredContentSize]

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Whisker Settings"
            window.contentViewController = hostingController
            window.setContentSize(hostingController.view.fittingSize)
            window.center()
            window.delegate = self
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            settingsWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
