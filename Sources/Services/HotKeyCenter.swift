import Carbon
import AppKit

/// Hotkey global lewat Carbon `RegisterEventHotKey` — diizinkan di Mac App
/// Store dan TIDAK butuh Accessibility / Input Monitoring.
final class HotKeyCenter {
    static let shared = HotKeyCenter()
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    var onTrigger: (() -> Void)?

    /// Default: ⌘⇧V.
    func register(keyCode: UInt32 = UInt32(kVK_ANSI_V),
                  modifiers: UInt32 = UInt32(cmdKey | shiftKey)) {
        unregister()

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let center = Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
            center.onTrigger?()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)

        let id = EventHotKeyID(signature: OSType(0x434C4950) /* 'CLIP' */, id: 1)
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef); self.hotKeyRef = nil }
        if let handlerRef { RemoveEventHandler(handlerRef); self.handlerRef = nil }
    }
}
