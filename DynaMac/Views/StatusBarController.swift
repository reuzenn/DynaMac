import Foundation
import AppKit
import SwiftUI

public final class SettingsWindowController: NSObject {
    public static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.window?.title = LocalizationManager.shared.t("settings_title")
        }
    }
    
    public func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = LocalizationManager.shared.t("settings_title")
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

public final class StatusBarController: NSObject, NSMenuDelegate {
    public static let shared = StatusBarController()
    
    private var statusItem: NSStatusItem?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMenu()
        }
    }
    
    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "DynaMac")
        button.image?.isTemplate = true
        
        updateMenu()
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        updateMenu()
    }
    
    public func updateMenu() {
        let l10n = LocalizationManager.shared
        let menu = NSMenu()
        menu.delegate = self
        
        let titleItem = NSMenuItem(title: l10n.t("menu_active"), action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        let deviceItem = NSMenuItem(title: NotchManager.shared.detectedDeviceName, action: nil, keyEquivalent: "")
        deviceItem.isEnabled = false
        menu.addItem(deviceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let isExpanded = NotchViewModel.shared.state.isExpanded
        let toggleTitle = isExpanded ? l10n.t("menu_collapse") : l10n.t("menu_expand")
        let toggleItem = NSMenuItem(
            title: toggleTitle,
            action: #selector(toggleNotch),
            keyEquivalent: "e"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let settingsItem = NSMenuItem(
            title: l10n.t("menu_settings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: l10n.t("menu_quit"),
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleNotch() {
        HapticService.play(.tap)
        NotchViewModel.shared.toggleExpandCollapse()
    }
    
    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
