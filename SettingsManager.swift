import Foundation
import Combine

enum TemperatureUnit: String, CaseIterable {
    case celsius = "C"
    case fahrenheit = "F"
}

class SettingsManager: ObservableObject {
    private static let temperatureUnitKey = "temperatureUnit"

    @Published var temperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: Self.temperatureUnitKey)
        }
    }

    init() {
        if let savedValue = UserDefaults.standard.string(forKey: Self.temperatureUnitKey),
           let unit = TemperatureUnit(rawValue: savedValue) {
            self.temperatureUnit = unit
        } else {
            self.temperatureUnit = .celsius
        }
    }

    func formatTemperature(_ celsius: Double) -> String {
        switch temperatureUnit {
        case .celsius:
            return String(format: "%.1f°C", celsius)
        case .fahrenheit:
            let fahrenheit = celsius * 9/5 + 32
            return String(format: "%.1f°F", fahrenheit)
        }
    }
}
