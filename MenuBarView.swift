import SwiftUI

struct MenuBarView: View {
    @ObservedObject var bluetoothManager: BluetoothManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Aranet4 Air Quality")
                    .font(.headline)
                Spacer()
                ConnectionStatusView(status: bluetoothManager.connectionStatus)
            }
            .padding(.bottom, 4)

            Divider()

            // Readings
            if let reading = bluetoothManager.currentReading {
                ReadingsView(reading: reading)
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }

            // Error message
            if let error = bluetoothManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(6)
            }

            Divider()

            // Last updated
            if let lastUpdated = bluetoothManager.lastUpdated {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Updated \(timeAgo(lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    bluetoothManager.refreshReadings()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(bluetoothManager.connectionStatus != .connected)

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Quit")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }
}

struct ReadingsView: View {
    let reading: Aranet4Reading

    var body: some View {
        VStack(spacing: 12) {
            // CO2 - most important
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CO2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(reading.co2)")
                            .font(.system(size: 32, weight: .bold))
                        Text("ppm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(reading.co2Status.color)
                            .font(.title2)
                    }
                }
                Spacer()
            }
            .padding()
            .background(co2Background(reading.co2Status))
            .cornerRadius(8)

            // Other readings
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ReadingCard(
                    icon: "thermometer",
                    label: "Temperature",
                    value: String(format: "%.1f°C", reading.temperature)
                )

                ReadingCard(
                    icon: "humidity",
                    label: "Humidity",
                    value: "\(reading.humidity)%"
                )

                ReadingCard(
                    icon: "gauge",
                    label: "Pressure",
                    value: String(format: "%.1f hPa", reading.pressure)
                )

                ReadingCard(
                    icon: "battery.100",
                    label: "Battery",
                    value: "\(reading.battery)%"
                )
            }
        }
    }

    private func co2Background(_ status: CO2Level) -> Color {
        switch status {
        case .good:
            return Color.green.opacity(0.12)
        case .moderate:
            return Color.yellow.opacity(0.12)
        case .poor:
            return Color.red.opacity(0.12)
        }
    }
}

struct ReadingCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(6)
    }
}

struct ConnectionStatusView: View {
    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var statusColor: Color {
        switch status {
        case .disconnected:
            return .red
        case .scanning, .connecting:
            return .orange
        case .connected:
            return .green
        }
    }

    private var statusText: String {
        switch status {
        case .disconnected:
            return "Disconnected"
        case .scanning:
            return "Scanning"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        }
    }
}
