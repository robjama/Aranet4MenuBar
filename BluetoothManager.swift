import Foundation
import CoreBluetooth
import Combine
import UserNotifications

extension String {
    func appendToFile(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            fileHandle.write(self.data(using: .utf8)!)
            fileHandle.closeFile()
        } else {
            try self.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var currentReading: Aranet4Reading?
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var aranet4Peripheral: CBPeripheral?
    private var currentReadingsCharacteristic: CBCharacteristic?
    private var refreshTimer: Timer?
    private var autoRefreshInterval: TimeInterval = 300 // 5 minutes

    // Alert settings
    private var co2AlertThreshold: Int = 1200 // ppm
    private var hasAlertedForHighCO2: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        requestNotificationPermissions()
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                NSLog("Notification permission granted")
            } else if let error = error {
                NSLog("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    private func sendHighCO2Alert(co2: Int) {
        let content = UNMutableNotificationContent()
        content.title = "High CO2 Alert"
        content.body = "CO2 level is \(co2) ppm. Consider opening a window or improving ventilation."
        content.sound = .default

        let request = UNNotificationRequest(identifier: "highCO2", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Public Methods

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not available"
            return
        }

        connectionStatus = .scanning
        errorMessage = nil

        let serviceUUIDs = [
            CBUUID(string: Aranet4UUIDs.serviceUUID),
            CBUUID(string: Aranet4UUIDs.serviceUUIDNew)
        ]

        centralManager.scanForPeripherals(
            withServices: serviceUUIDs,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        print("Scanning for Aranet4 devices...")
    }

    func stopScanning() {
        centralManager.stopScan()
        print("Stopped scanning")
    }

    func refreshReadings() {
        guard let characteristic = currentReadingsCharacteristic,
              let peripheral = aranet4Peripheral else {
            errorMessage = "Not connected to device"
            return
        }

        print("Refreshing readings...")
        peripheral.readValue(for: characteristic)
    }

    func disconnect() {
        if let peripheral = aranet4Peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        stopRefreshTimer()
    }

    // MARK: - Private Methods

    private func startRefreshTimer() {
        stopRefreshTimer()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            self?.refreshReadings()
        }
    }

    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            startScanning()
        case .poweredOff:
            connectionStatus = .disconnected
            errorMessage = "Bluetooth is powered off"
        case .unauthorized:
            connectionStatus = .disconnected
            errorMessage = "Bluetooth permission denied"
        case .unsupported:
            connectionStatus = .disconnected
            errorMessage = "Bluetooth not supported"
        default:
            connectionStatus = .disconnected
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered Aranet4: \(peripheral.name ?? "Unknown")")

        // Auto-connect to first Aranet4 found
        aranet4Peripheral = peripheral
        aranet4Peripheral?.delegate = self
        connectionStatus = .connecting
        stopScanning()

        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Aranet4")")
        connectionStatus = .connected
        errorMessage = nil

        // Discover services
        let serviceUUIDs = [
            CBUUID(string: Aranet4UUIDs.serviceUUID),
            CBUUID(string: Aranet4UUIDs.serviceUUIDNew)
        ]
        peripheral.discoverServices(serviceUUIDs)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        connectionStatus = .disconnected
        errorMessage = "Failed to connect to device"
        aranet4Peripheral = nil

        // Retry scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.startScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from device")
        connectionStatus = .disconnected
        aranet4Peripheral = nil
        currentReadingsCharacteristic = nil
        stopRefreshTimer()

        // Retry scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.startScanning()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            print("Discovered service: \(service.uuid)")
            let characteristicUUID = CBUUID(string: Aranet4UUIDs.currentReadingsUUID)
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")

            // Try both current readings characteristics
            let currentUUID = CBUUID(string: Aranet4UUIDs.currentReadingsUUID)
            let detailedUUID = CBUUID(string: Aranet4UUIDs.currentReadingsDetailedUUID)

            if characteristic.uuid == currentUUID || characteristic.uuid == detailedUUID {
                currentReadingsCharacteristic = characteristic
                NSLog("Using characteristic: \(characteristic.uuid.uuidString)")
                // Read initial value
                peripheral.readValue(for: characteristic)
                // Start auto-refresh timer
                startRefreshTimer()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            let errMsg = "Error reading characteristic: \(error!.localizedDescription)"
            print(errMsg)
            NSLog(errMsg)
            errorMessage = "Failed to read sensor data"
            return
        }

        guard let data = characteristic.value else {
            let msg = "No data received from characteristic"
            print(msg)
            NSLog(msg)
            return
        }

        let hexString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
        let msg = "Received data: \(data.count) bytes - \(hexString)"
        print(msg)
        NSLog(msg)

        // Write to debug file
        let debugFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("aranet4_debug.txt")
        let debugMsg = "\(Date()): \(data.count) bytes - \(hexString)\n"
        try? debugMsg.appendToFile(at: debugFile)

        // Decode the reading
        if let reading = Aranet4Reading.decode(from: data) {
            DispatchQueue.main.async {
                self.currentReading = reading
                self.lastUpdated = Date()
                self.errorMessage = nil
                let successMsg = "CO2: \(reading.co2) ppm, Temp: \(reading.temperature)°C, Humidity: \(reading.humidity)%, Pressure: \(reading.pressure) hPa, Battery: \(reading.battery)%"
                print(successMsg)
                NSLog(successMsg)

                // Check for high CO2 and send alert
                self.checkCO2Level(reading.co2)
            }
        } else {
            let errMsg = "Failed to decode reading from \(data.count) bytes"
            print(errMsg)
            NSLog(errMsg)
            errorMessage = "Failed to decode sensor data"
        }
    }

    private func checkCO2Level(_ co2: Int) {
        if co2 >= co2AlertThreshold {
            if !hasAlertedForHighCO2 {
                sendHighCO2Alert(co2: co2)
                hasAlertedForHighCO2 = true
            }
        } else {
            // Reset alert flag when CO2 drops below threshold
            hasAlertedForHighCO2 = false
        }
    }
}
