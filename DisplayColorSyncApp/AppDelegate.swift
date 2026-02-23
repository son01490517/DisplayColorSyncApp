import Cocoa
import UserNotifications

@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowRestoration, NSWindowDelegate, UNUserNotificationCenterDelegate {
    var window: NSWindow?
    var monitor: DisplayMonitor?
    var iccTimer: Timer?
    var statusItem: NSStatusItem?
    var processMonitor: ProcessMonitor?
    var isAutoApplyEnabled: Bool = true {
        didSet {
            if isAutoApplyEnabled {
                startAutoApplyTimer()
            } else {
                stopAutoApplyTimer()
            }
            // Notify ViewController to update UI
            if let viewController = window?.contentViewController as? ViewController {
                viewController.updateAutoApplyStatus(isAutoApplyEnabled)
            }
        }
    }
    var wasAutoApplyEnabledBeforePause: Bool = true // Save auto-apply state before pause
    var isPausedByCalibrationApp: Bool = false // Indicates if auto-apply was paused by a calibration app
    let displayManager = DisplayManager()
    let iccManager = ICCProfileManager()

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func application(_ application: NSApplication, restoreWindowWithIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        if identifier.rawValue == "MainWindow" {
            if window == nil {
                setupMainWindow()
            }
            completionHandler(window, nil)
        } else {
            completionHandler(nil, nil)
        }
    }
    
    // MARK: - NSWindowRestoration
    static func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            completionHandler(nil, nil)
            return
        }
        
        if identifier.rawValue == "MainWindow" {
            if appDelegate.window == nil {
                appDelegate.setupMainWindow()
            }
            completionHandler(appDelegate.window, nil)
        } else {
            completionHandler(nil, nil)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 App started in minimized mode (no main window)")
        setupStatusBarItem()
        
        // Setup and request notification permission
        setupNotifications()

        monitor = DisplayMonitor(onChange: handleDisplayChange)
        
        // Setup process monitor to watch calibration apps
        setupProcessMonitor()
        
        if isAutoApplyEnabled {
            startAutoApplyTimer()
        }
        handleDisplayChange()
        
        // Send notification to inform user app is running
        sendStartupNotification()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show window when user clicks dock icon
        showMainWindow(nil)
        return true
    }

    // MARK: - Notifications
    
    func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        // Request authorization
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification authorization error: \(error.localizedDescription)")
            } else if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    func sendStartupNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Display Color Sync"
        content.body = "The app is running in the background. Click the menu bar icon to open the window."
        content.sound = .default
        
        // Create trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        
        let request = UNNotificationRequest(identifier: "startup-notification", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ Startup notification sent")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification click - open main window
        if response.notification.request.identifier == "startup-notification" {
            showMainWindow(nil)
        }
        completionHandler()
    }

    // MARK: - Status Bar Item

    func setupStatusBarItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem = statusItem

        if let button = statusItem.button {
            if let image = NSImage(named: "StatusBarIcon") {
                image.isTemplate = true
                // Make the status bar icon as large as reasonable for the menu bar
                image.size = NSSize(width: 20, height: 20)
                button.image = image
                statusItem.length = NSStatusItem.squareLength
            } else {
                statusItem.length = NSStatusItem.variableLength
                button.title = "DisplayColorSync"
            }
            button.toolTip = "Display Color Sync"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open window", action: #selector(showMainWindow(_:)), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    func setupMainWindow() {
        print("📱 Setting up main window...")
        
        // Get screen frame to center window properly
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let windowRect = NSRect(
            x: (screenFrame.width - 480) / 2,
            y: (screenFrame.height - 320) / 2,
            width: 480,
            height: 320
        )
        
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Display Color Sync"
        window.identifier = NSUserInterfaceItemIdentifier("MainWindow")
        // Temporarily disable restoration to ensure window shows
        window.isRestorable = false
        // window.restorationClass = AppDelegate.self
        
        // Set window delegate to handle window closing
        window.delegate = self

        let viewController = ViewController()
        viewController.appDelegate = self
        window.contentViewController = viewController
        
        // Update UI with current auto-apply status
        viewController.updateAutoApplyStatus(isAutoApplyEnabled)

        self.window = window
        print("✅ Window created (not automatically shown at launch)")
    }

    @objc func showMainWindow(_ sender: Any?) {
        if window == nil {
            setupMainWindow()
        }
        guard let window = window else { return }
        
        // Switch to regular activation policy to show Dock icon
        NSApp.setActivationPolicy(.regular)
        
        // Setup menu bar with Quit item for Command+Q to work
        setupMenuBar()
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setupMenuBar() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        appMenu.addItem(NSMenuItem(title: "Quit Display Color Sync", action: #selector(quitApp(_:)), keyEquivalent: "q"))
        appMenu.items.forEach { $0.target = self }
        
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    @objc func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // When window closes, switch back to accessory policy to hide Dock icon
        // But keep the window object so it can be reopened
        NSApp.setActivationPolicy(.accessory)
        NSApp.mainMenu = nil
    }
    
    func windowDidMiniaturize(_ notification: Notification) {
        // When window is minimized, hide Dock icon but keep status bar icon
        NSApp.setActivationPolicy(.accessory)
        NSApp.mainMenu = nil
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        // When window is restored from minimized state, show Dock icon again
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()
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
        stopAutoApplyTimer() // Stop existing timer if any
        iccTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            print("🔁 Auto-reapplying ICC profiles (5s interval)")
            self.handleDisplayChange()
        }
        RunLoop.current.add(iccTimer!, forMode: .common)
        print("✅ Auto-apply timer started")
    }
    
    func stopAutoApplyTimer() {
        iccTimer?.invalidate()
        iccTimer = nil
        print("⏸️ Auto-apply timer stopped")
    }
    
    func toggleAutoApply() {
        // If auto-apply was paused by a calibration app and the user turns it back on,
        // update the flag so it will not be automatically restored later
        if isPausedByCalibrationApp && !isAutoApplyEnabled {
            wasAutoApplyEnabledBeforePause = false
            isPausedByCalibrationApp = false
        }
        isAutoApplyEnabled.toggle()
    }
    
    func resetGammaToDefault() {
        let displays = displayManager.getAllDisplays()
        let displayIDs = displays.map { $0.id }
        iccManager.resetAllDisplaysToDefault(displayIDs: displayIDs)
        print("✅ Reset gamma tables to default completed")
        
        // Automatically turn off ICC auto-apply after reset
        if isAutoApplyEnabled {
            isAutoApplyEnabled = false
            print("⏸️ Auto-apply has been turned off after reset")
        }
    }
    
    // MARK: - Process Monitor
    
    func setupProcessMonitor() {
        processMonitor = ProcessMonitor()
        processMonitor?.onStateChanged = { [weak self] calibrationAppRunning in
            guard let self = self else { return }
            
            if calibrationAppRunning {
                // Calibration app is running - pause auto-apply
                if self.isAutoApplyEnabled {
                    self.wasAutoApplyEnabledBeforePause = true
                    self.isPausedByCalibrationApp = true
                    self.isAutoApplyEnabled = false
                    self.sendCalibrationAppDetectedNotification()
                    print("⏸️ Auto-apply paused due to calibration app")
                }
            } else {
                // Calibration app has closed - restore auto-apply if it was previously enabled
                if self.isPausedByCalibrationApp && self.wasAutoApplyEnabledBeforePause && !self.isAutoApplyEnabled {
                    self.isAutoApplyEnabled = true
                    self.isPausedByCalibrationApp = false
                    self.sendCalibrationAppClosedNotification()
                    print("✅ Auto-apply resumed after calibration app closed")
                } else if self.isPausedByCalibrationApp {
                    // Reset flag when calibration app is no longer running
                    self.isPausedByCalibrationApp = false
                }
            }
        }
        
        processMonitor?.startMonitoring()
    }
    
    func sendCalibrationAppDetectedNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Display Color Sync"
        content.body = "A calibration application is running. ICC auto-apply has been paused."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: "calibration-app-detected-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send calibration app detected notification: \(error.localizedDescription)")
            } else {
                print("✅ Calibration app detected notification sent")
            }
        }
    }
    
    func sendCalibrationAppClosedNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Display Color Sync"
        content.body = "The calibration application has closed. ICC auto-apply has been restored."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: "calibration-app-closed-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send calibration app closed notification: \(error.localizedDescription)")
            } else {
                print("✅ Calibration app closed notification sent")
            }
        }
    }
}
