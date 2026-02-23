import Foundation
import CoreGraphics
import ColorSync

class ICCProfileManager {
    func applyICCProfile(to displayID: CGDirectDisplayID, profilePath: String) {
        guard let displayUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            print("❌ Failed to get UUID for displayID: \(displayID)")
            return
        }

        let profileURL = URL(fileURLWithPath: profilePath) as CFURL

        let profileDict: [CFString: Any] = [
            kColorSyncDeviceDefaultProfileID.takeUnretainedValue(): profileURL,
            kColorSyncProfileUserScope.takeUnretainedValue(): kCFPreferencesCurrentUser
        ]

        let success = ColorSyncDeviceSetCustomProfiles(
            kColorSyncDisplayDeviceClass.takeUnretainedValue(),
            displayUUID,
            profileDict as CFDictionary
        )

        if success {
            print("✅ ICC profile applied to display UUID: \(displayUUID)")
        } else {
            print("❌ Failed to apply ICC profile to UUID: \(displayUUID)")
        }
    }
    
    /// Clear custom ICC profile for a display (ColorSyncDeviceSetCustomProfiles with nil value)
    /// Return display to use the system default profile
    func clearCustomProfile(for displayID: CGDirectDisplayID) -> Bool {
        guard let displayUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            print("❌ Failed to get UUID for displayID: \(displayID)")
            return false
        }
        
        let defaultProfileKey = kColorSyncDeviceDefaultProfileID.takeUnretainedValue()
        
        // Use NSMutableDictionary with NSNull() to represent nil
        // Convert CFString to NSString to conform to NSCopying
        print("🔍 Clearing custom ICC profile using NSMutableDictionary with NSNull()...")
        let resetProfileDict = NSMutableDictionary()
        resetProfileDict.setObject(NSNull(), forKey: defaultProfileKey as NSString)
        
        let success = ColorSyncDeviceSetCustomProfiles(
            kColorSyncDisplayDeviceClass.takeUnretainedValue(),
            displayUUID,
            resetProfileDict as CFDictionary
        )
        
        if success {
            print("✅ Custom ICC profile cleared for displayID: \(displayID)")
            return true
        }
        
        print("⚠️ Failed to clear custom profile via ColorSync API for displayID: \(displayID)")
        print("   (Gamma table reset will still be applied)")
        return false
    }
    
    /// Reset gamma table to default (linear) for a display
    /// Based on the gamma table reset logic from dispwin -c
    func resetGammaTableToDefault(for displayID: CGDirectDisplayID) -> Bool {
        // Get the number of entries in the gamma table
        let capacity = CGDisplayGammaTableCapacity(displayID)
        guard capacity > 0 else {
            print("❌ Failed to get gamma table capacity for displayID: \(displayID)")
            return false
        }
        
        let nent = Int(capacity)
        print("📊 Gamma table capacity: \(nent) entries")
        
        // Create a linear gamma table: each entry i = i/(nent-1.0) for R, G, B
        var redValues = [CGGammaValue](repeating: 0, count: nent)
        var greenValues = [CGGammaValue](repeating: 0, count: nent)
        var blueValues = [CGGammaValue](repeating: 0, count: nent)
        
        for i in 0..<nent {
            let val = Double(i) / Double(nent - 1)
            // Ensure the value is within [0.0, 1.0]
            let clampedVal = max(0.0, min(1.0, val))
            redValues[i] = CGGammaValue(clampedVal)
            greenValues[i] = CGGammaValue(clampedVal)
            blueValues[i] = CGGammaValue(clampedVal)
        }
        
        // Apply the linear gamma table to the display
        let result = CGSetDisplayTransferByTable(
            displayID,
            UInt32(nent),
            redValues,
            greenValues,
            blueValues
        )
        
        if result == .success {
            print("✅ Gamma table reset to linear (default) for displayID: \(displayID)")
            return true
        } else {
            print("❌ Failed to reset gamma table for displayID: \(displayID), error: \(result.rawValue)")
            return false
        }
    }
    
    /// Reset ICC to default: clear custom profile (ColorSync) + reset gamma table (Core Graphics)
    func resetAllDisplaysToDefault(displayIDs: [CGDirectDisplayID]) {
        print("🔄 Resetting ICC to default for all displays...")
        for displayID in displayIDs {
            _ = clearCustomProfile(for: displayID)
            _ = resetGammaTableToDefault(for: displayID)
        }
    }
}
