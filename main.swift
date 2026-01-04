import AppKit

// Create and configure the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Set activation policy before running
app.setActivationPolicy(.accessory)

// Run the app
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
