import AppKit
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleMenuBar = Self("toggleMenuBar", default: .init(.y, modifiers: [.command, .shift]))
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?
    var isHidden = false

    let hiddenLength: CGFloat = 10_000
    let hiddenStateKey = "WhiskerIsHidden"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupStatusItem()
        setupKeyboardShortcut()

        isHidden = UserDefaults.standard.bool(forKey: hiddenStateKey)
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
            if let image = NSImage(systemSymbolName: "circlebadge.fill", accessibilityDescription: "Whisker") {
                image.isTemplate = true
                button.image = image
            }
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
            statusItem.length = hiddenLength
            statusItem.button?.image = nil
        } else {
            statusItem.length = NSStatusItem.variableLength
            if let image = NSImage(systemSymbolName: "circlebadge.fill", accessibilityDescription: "Whisker") {
                image.isTemplate = true
                statusItem.button?.image = image
            }
        }
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
