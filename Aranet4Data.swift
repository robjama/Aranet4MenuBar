import Foundation

// MARK: - Connection Status

enum ConnectionStatus {
    case disconnected
    case scanning
    case connecting
    case connected
}

// MARK: - Aranet4 Reading

struct Aranet4Reading {
    let co2: Int           // ppm
    let temperature: Double // Celsius
    let pressure: Double   // hPa
    let humidity: Int      // percent
    let battery: Int       // percent
    let timestamp: Date

    init(co2: Int, temperature: Double, pressure: Double, humidity: Int, battery: Int, timestamp: Date = Date()) {
        self.co2 = co2
        self.temperature = temperature
        self.pressure = pressure
        self.humidity = humidity
        self.battery = battery
        self.timestamp = timestamp
    }

    // Decode from Aranet4 current readings characteristic (f0cd1503-95da-4f4b-9ac8-aa55d312af0c)
    // Data format: CO2(u16LE), Temperature(u16LE), Pressure(u16LE), Humidity(u8), Battery(u8), Status(u8), Interval(u16LE), Ago(u16LE)
    static func decode(from data: Data) -> Aranet4Reading? {
        NSLog("Decoding \(data.count) bytes")

        // Try 7-byte format first (basic reading without interval/ago)
        if data.count >= 7 {
            let co2 = Int(data[0]) | (Int(data[1]) << 8)
            let tempRaw = Int(data[2]) | (Int(data[3]) << 8)
            let pressureRaw = Int(data[4]) | (Int(data[5]) << 8)
            let humidity = Int(data[6])

            // Try to get battery if available
            let battery = data.count >= 8 ? Int(data[7]) : 100

            // Convert temperature: divide by 20 to get Celsius (0.05 multiplier)
            let temperature = Double(tempRaw) / 20.0

            // Convert pressure: divide by 10 to get hPa (0.1 multiplier)
            let pressure = Double(pressureRaw) / 10.0

            NSLog("Decoded: CO2=\(co2), Temp=\(temperature), Press=\(pressure), Hum=\(humidity), Batt=\(battery)")

            return Aranet4Reading(
                co2: co2,
                temperature: temperature,
                pressure: pressure,
                humidity: humidity,
                battery: battery
            )
        }

        NSLog("Data too small: \(data.count) bytes")
        return nil
    }

    // Format for menu bar display
    var menuBarText: String {
        return "CO2: \(co2) T: \(String(format: "%.1f", temperature))°C"
    }

    // Get CO2 level status
    var co2Status: CO2Level {
        if co2 < 800 {
            return .good
        } else if co2 < 1200 {
            return .moderate
        } else {
            return .poor
        }
    }
}

// MARK: - CO2 Level Status

enum CO2Level {
    case good      // < 800 ppm
    case moderate  // 800-1199 ppm
    case poor      // >= 1200 ppm

    var color: String {
        switch self {
        case .good: return "🟢"
        case .moderate: return "🟡"
        case .poor: return "🔴"
        }
    }
}

// MARK: - Aranet4 UUIDs

struct Aranet4UUIDs {
    // Service UUID (before v1.2.0)
    static let serviceUUID = "f0cd1400-95da-4f4b-9ac8-aa55d312af0c"

    // Alternative Service UUID (v1.2.0+)
    static let serviceUUIDNew = "0000fce0-0000-1000-8000-00805f9b34fb"

    // Current readings characteristic
    static let currentReadingsUUID = "f0cd1503-95da-4f4b-9ac8-aa55d312af0c"

    // Current readings + interval + ago
    static let currentReadingsDetailedUUID = "f0cd3001-95da-4f4b-9ac8-aa55d312af0c"
}
