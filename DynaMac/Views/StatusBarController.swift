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
    
    // The menu is built once and only its titles are refreshed. Replacing the NSMenu
    // instance while it is opening interrupts menu tracking and causes stutter.
    private let menu = NSMenu()
    private let titleItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let deviceItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: "", action: nil, keyEquivalent: "e")
    private let settingsItem = NSMenuItem(title: "", action: nil, keyEquivalent: ",")
    private let quitItem = NSMenuItem(title: "", action: nil, keyEquivalent: "q")
    
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
        
        buildMenu()
        updateMenu()
        statusItem?.menu = menu
    }
    
    private func buildMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
        
        titleItem.isEnabled = false
        deviceItem.isEnabled = false
        
        toggleItem.action = #selector(toggleNotch)
        toggleItem.target = self
        settingsItem.action = #selector(openSettings)
        settingsItem.target = self
        quitItem.action = #selector(quitApp)
        quitItem.target = self
        
        menu.addItem(titleItem)
        menu.addItem(deviceItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(toggleItem)
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
    }
    
    /// Called by AppKit right before the menu is displayed; only cheap title updates happen here.
    public func menuNeedsUpdate(_ menu: NSMenu) {
        updateMenu()
    }
    
    public func updateMenu() {
        let l10n = LocalizationManager.shared
        titleItem.title = l10n.t("menu_active")
        deviceItem.title = NotchManager.shared.detectedDeviceName
        toggleItem.title = NotchViewModel.shared.state.isExpanded ? l10n.t("menu_collapse") : l10n.t("menu_expand")
        settingsItem.title = l10n.t("menu_settings")
        quitItem.title = l10n.t("menu_quit")
    }
    
    @objc private func toggleNotch() {
        HapticService.play(.tap)
        // Defer until the menu has fully closed so the island animation is not
        // started while AppKit is still tearing down menu tracking.
        DispatchQueue.main.async {
            NotchViewModel.shared.toggleExpandCollapse()
        }
    }
    
    @objc private func openSettings() {
        DispatchQueue.main.async {
            SettingsWindowController.shared.show()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
