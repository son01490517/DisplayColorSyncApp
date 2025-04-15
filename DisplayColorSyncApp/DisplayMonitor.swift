import CoreGraphics

class DisplayMonitor {
    static var sharedInstance: DisplayMonitor?

    let onChange: () -> Void
    private var pendingWorkItem: DispatchWorkItem?

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        DisplayMonitor.sharedInstance = self
        startMonitoring()
    }

    private func startMonitoring() {
        CGDisplayRegisterReconfigurationCallback(displayCallback, nil)
    }

    deinit {
        CGDisplayRemoveReconfigurationCallback(displayCallback, nil)
    }

    func triggerChangeDebounced() {
        pendingWorkItem?.cancel()

        let work = DispatchWorkItem {
            self.onChange()
        }

        pendingWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }
}

private let displayCallback: CGDisplayReconfigurationCallBack = { _, _, _ in
    print("📡 Display(s) event → Wait 2s before reapply")
    DisplayMonitor.sharedInstance?.triggerChangeDebounced()
}
