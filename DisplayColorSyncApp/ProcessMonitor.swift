import Cocoa

class ProcessMonitor {
    // List of calibration applications to watch (name contains or matches exactly)
    private let calibrationApps = [
        "calibrite PROFILER",
        "DisplayCal",
        "i1profiler"
    ]
    
    // List of app name prefixes (any app starting with these will also be treated as calibration apps)
    private let calibrationAppPrefixes = [
        "Spyder"
    ]
    
    private var checkTimer: Timer?
    private var previousState: Bool = false // false = no calibration app running, true = at least one calibration app running
    
    // Callback when state changes
    var onStateChanged: ((Bool) -> Void)? // true = a calibration app is running
    
    func startMonitoring() {
        stopMonitoring() // Stop existing timer if any
        
        // Check immediately once
        checkCalibrationApps()
        
        // Set up timer to check every 5 seconds
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkCalibrationApps()
        }
        RunLoop.current.add(checkTimer!, forMode: .common)
        print("✅ ProcessMonitor started - monitoring calibration apps")
    }
    
    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        print("⏸️ ProcessMonitor stopped")
    }
    
    private func checkCalibrationApps() {
        let runningApps = NSWorkspace.shared.runningApplications
        var foundAny = false
        
        for app in runningApps {
            if let appName = app.localizedName {
                let appNameLower = appName.lowercased()
                for calibrationApp in calibrationApps {
                    let calibrationAppLower = calibrationApp.lowercased()
                    if appNameLower.contains(calibrationAppLower) || appNameLower == calibrationAppLower {
                        foundAny = true
                        print("🔍 Found calibration app running: \(appName)")
                        break
                    }
                }
                if !foundAny {
                    for prefix in calibrationAppPrefixes {
                        if appNameLower.hasPrefix(prefix.lowercased()) {
                            foundAny = true
                            print("🔍 Found calibration app running (prefix): \(appName)")
                            break
                        }
                    }
                }
                if foundAny {
                    break
                }
            }
        }
        
        // Only call the callback when state changes
        if foundAny != previousState {
            previousState = foundAny
            onStateChanged?(foundAny)
            
            if foundAny {
                print("⚠️ Calibration app detected - auto-apply should be paused")
            } else {
                print("✅ No calibration apps running - auto-apply can resume")
            }
        }
    }
    
    /// Kiểm tra xem có app calibration nào đang chạy không (synchronous)
    func isCalibrationAppRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if let appName = app.localizedName {
                let appNameLower = appName.lowercased()
                for calibrationApp in calibrationApps {
                    let calibrationAppLower = calibrationApp.lowercased()
                    if appNameLower.contains(calibrationAppLower) || appNameLower == calibrationAppLower {
                        return true
                    }
                }
                for prefix in calibrationAppPrefixes {
                    if appNameLower.hasPrefix(prefix.lowercased()) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}
