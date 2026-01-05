import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItemController: StatusItemController?
    var bluetoothManager: BluetoothManager?
    var settingsManager: SettingsManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched!")
        NSLog("App launched!")

        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)

        // Initialize managers
        bluetoothManager = BluetoothManager()
        settingsManager = SettingsManager()

        // Initialize status item controller
        statusItemController = StatusItemController(bluetoothManager: bluetoothManager!, settingsManager: settingsManager!)

        print("Status item created")
        NSLog("Status item created")
    }

    func applicationWillTerminate(_ notification: Notification) {
        bluetoothManager?.disconnect()
    }
}
