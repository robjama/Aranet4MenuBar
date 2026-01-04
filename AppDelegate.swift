import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItemController: StatusItemController?
    var bluetoothManager: BluetoothManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched!")
        NSLog("App launched!")

        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)

        // Initialize Bluetooth manager
        bluetoothManager = BluetoothManager()

        // Initialize status item controller
        statusItemController = StatusItemController(bluetoothManager: bluetoothManager!)

        print("Status item created")
        NSLog("Status item created")
    }

    func applicationWillTerminate(_ notification: Notification) {
        bluetoothManager?.disconnect()
    }
}
