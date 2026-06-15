import ServiceManagement
import Foundation

/// "Buka saat login" lewat SMAppService — sesuai aturan App Store: hanya aktif
/// kalau pengguna sendiri menyalakannya (default mati, dikontrol toggle).
enum LoginItem {
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            NSLog("ClipNest LoginItem error: \(error.localizedDescription)")
            return false
        }
    }
}
