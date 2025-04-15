import Foundation

class DisplayPresetMonitor: NSObject {
    private var displayManager: MPDisplayMgr?

    override init() {
        super.init()
        displayManager = MPDisplayMgr()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presetDidChange),
            name: NSNotification.Name("MPDisplayPresetChangedNotification"),
            object: nil
        )
        
        logCurrentPreset()
    }

    @objc private func presetDidChange(notification: Notification) {
        print("🎛️ Reference Mode đã thay đổi!")
        logCurrentPreset()
    }

    private func logCurrentPreset() {
        guard let displays = displayManager?.displays as? [MPDisplay] else { return }

        for display in displays {
            let name = display.displayName ?? "Unknown"
            let presetName = display.activePreset?.presetName ?? "Unknown"
            print("🖥️ \(name) → preset hiện tại: \(presetName)")
        }
    }
}
