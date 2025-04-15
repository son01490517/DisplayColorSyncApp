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
}
