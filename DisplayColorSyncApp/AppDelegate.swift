import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var monitor: DisplayMonitor?
    var iccTimer: Timer?
    let displayManager = DisplayManager()
    let iccManager = ICCProfileManager()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 Background app has started")
        monitor = DisplayMonitor(onChange: handleDisplayChange)
        startAutoApplyTimer()
        handleDisplayChange()
    }

    func handleDisplayChange() {
        let displays = displayManager.getAllDisplays()
        for display in displays {
            print("🖥️ \(display.name) | ICC: \(display.iccProfilePath ?? "Not Available")")
            if let iccPath = display.iccProfilePath {
                iccManager.applyICCProfile(to: display.id, profilePath: iccPath)
            }
        }
    }

    func startAutoApplyTimer() {
        iccTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            print("🔁 Auto-reapplying ICC profiles (5s interval)")
            self.handleDisplayChange()
        }
        RunLoop.current.add(iccTimer!, forMode: .common)
    }
}
