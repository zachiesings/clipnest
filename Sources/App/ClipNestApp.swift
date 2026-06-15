import SwiftUI
import AppKit
import Combine

/// Model bersama (history + Pro + monitor + setelan). Singleton supaya bisa
/// dipakai baik oleh AppDelegate (popover) maupun scene Settings SwiftUI.
@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    let history = HistoryStore()
    let pro = ProStore()
    let monitor = ClipboardMonitor()
    let settings = Settings.shared

    private var bag = Set<AnyCancellable>()

    private init() {
        monitor.onNewItem = { [weak self] item in
            guard let self else { return }
            self.history.add(item)
        }
        // Status Pro → batas riwayat.
        pro.$isPro
            .receive(on: RunLoop.main)
            .sink { [weak self] value in self?.history.isPro = value }
            .store(in: &bag)

        history.isPro = pro.isPro
        monitor.start()
    }
}

@main
struct ClipNestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(AppModel.shared)
        }
    }
}

/// Mengatur ikon menu bar + popover + hotkey global.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = AppModel.shared

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                   accessibilityDescription: "ClipNest")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 380, height: 520)
        popover.contentViewController = NSHostingController(
            rootView: HistoryView(onClose: { [weak self] in self?.popover.performClose(nil) })
                .environmentObject(model)
        )

        HotKeyCenter.shared.onTrigger = { [weak self] in self?.togglePopover() }
        HotKeyCenter.shared.register()
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyCenter.shared.unregister()
        AppModel.shared.monitor.stop()
    }
}
