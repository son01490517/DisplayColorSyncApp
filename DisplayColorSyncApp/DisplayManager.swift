import Foundation
import CoreGraphics
import ColorSync
import IOKit
import IOKit.graphics
import AppKit

struct DisplayInfo {
    let id: CGDirectDisplayID
    let name: String
    let iccProfilePath: String?
}

class DisplayManager {
    func getAllDisplays() -> [DisplayInfo] {
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount)

        return displayIDs.map { id in
            let name = getDisplayName(for: id)
            let iccPath = getICCProfilePath(for: id)
            return DisplayInfo(id: id, name: name, iccProfilePath: iccPath)
        }
    }

    private func getICCProfilePath(for displayID: CGDirectDisplayID) -> String? {
        guard let profile = ColorSyncProfileCreateWithDisplayID(displayID)?.takeRetainedValue(),
              let cfURL = ColorSyncProfileGetURL(profile, nil)?.takeUnretainedValue() else {
            return nil
        }
        return (cfURL as URL).path
    }

    func getDisplayName(for displayID: CGDirectDisplayID) -> String {
        var servicePort: io_service_t = 0
        servicePort = IOServicePortFromCGDisplayID(displayID)

        if servicePort != 0 {
            if let info = IODisplayCreateInfoDictionary(servicePort, IOOptionBits(kIODisplayOnlyPreferredName)).takeRetainedValue() as? [String: Any],
               let productName = info["DisplayProductName"] as? [String: String],
               let name = productName.values.first {
                IOObjectRelease(servicePort)
                return name
            }
            IOObjectRelease(servicePort)
        }

        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
               CGDirectDisplayID(screenNumber.uint32Value) == displayID {
                return screen.localizedName
            }
        }

        return "Unknown"
    }

    private func IOServicePortFromCGDisplayID(_ displayID: CGDirectDisplayID) -> io_service_t {
        var servicePortIterator = io_iterator_t()
        let matching = IOServiceMatching("IODisplayConnect")

        let ioPort: mach_port_t
        if #available(macOS 12.0, *) {
            ioPort = kIOMainPortDefault
        } else {
            ioPort = kIOMasterPortDefault
        }

        guard IOServiceGetMatchingServices(ioPort, matching, &servicePortIterator) == KERN_SUCCESS else {
            return 0
        }

        while case let service = IOIteratorNext(servicePortIterator), service != 0 {
            let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName)).takeRetainedValue() as NSDictionary
            let vendorID = info[kDisplayVendorID] as? UInt32
            let productID = info[kDisplayProductID] as? UInt32

            if vendorID == CGDisplayVendorNumber(displayID),
               productID == CGDisplayModelNumber(displayID) {
                IOObjectRelease(servicePortIterator)
                return service
            }
            IOObjectRelease(service)
        }

        return 0
    }
}
