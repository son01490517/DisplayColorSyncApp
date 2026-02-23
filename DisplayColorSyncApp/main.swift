import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Start with accessory policy (no Dock icon)
app.setActivationPolicy(.accessory)

// Start the app
app.run()
