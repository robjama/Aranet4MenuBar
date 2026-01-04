# Aranet4 Menu Bar App

A native macOS menu bar application that displays real-time air quality readings from your Aranet4 device via Bluetooth.

![Menu Bar Screenshot](https://via.placeholder.com/400x100?text=Menu+Bar+Screenshot)
*Screenshot placeholder - add your own screenshot here*

## Features

- 📊 **Live readings** - Shows CO2 and temperature directly in the menu bar
- 🔄 **Auto-connect** - Automatically finds and connects to your Aranet4
- ⏰ **Auto-refresh** - Updates readings every 5 minutes
- 🎨 **Color-coded CO2** - Visual indicators for air quality (🟢 good, 🟡 moderate, 🔴 poor)
- 📱 **Complete data** - View CO2, temperature, humidity, pressure, and battery level
- 🔋 **Lightweight** - Native Swift app, minimal resource usage
- 🔒 **Privacy-focused** - All data stays on your device, no internet required

## Requirements

- macOS 11.0 or later
- Aranet4 air quality sensor
- Bluetooth enabled

## Download

**Option 1: Download Pre-built App** (Coming soon)
- Download the latest release from the [Releases](../../releases) page
- Unzip and drag to Applications folder

**Option 2: Build from Source**
- Clone this repository
- Run `./build.sh`
- Copy `build/Aranet4MenuBar.app` to `/Applications/`

## Setup Instructions

### Option 1: Create Xcode Project Manually

1. Open Xcode
2. Create a new project: **File > New > Project**
3. Select **macOS > App**
4. Configure the project:
   - Product Name: `Aranet4MenuBar`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Save in: `/Users/rj/Aranet4MenuBar`
5. In the project navigator, **delete** the default ContentView.swift and Aranet4MenuBarApp.swift files that Xcode created
6. The existing Swift files in the folder will be automatically detected
7. If not, drag and drop the following files into your Xcode project:
   - Aranet4MenuBarApp.swift
   - BluetoothManager.swift
   - Aranet4Data.swift
   - StatusItemController.swift
   - MenuBarView.swift
8. Configure the project settings:
   - Select your project in the navigator
   - Go to **Signing & Capabilities** tab
   - Enable **App Sandbox**
   - Check **Bluetooth** under App Sandbox
   - Click **+ Capability** and add the **Bluetooth** capability
9. In the **Info** tab:
   - Add custom iOS target properties:
   - Key: `NSBluetoothAlwaysUsageDescription`
   - Value: `This app needs Bluetooth access to connect to your Aranet4 air quality sensor.`
   - Or replace the Info.plist with the provided one
10. Set deployment target to macOS 11.0 or later
11. Build and run!

### Option 2: Use the Build Script (Experimental)

Run the build script:

```bash
cd /Users/rj/Aranet4MenuBar
./build.sh
```

This will attempt to compile the app using swiftc.

## Usage

1. Make sure your Aranet4 device is powered on and nearby
2. Launch the app
3. The app will appear in your menu bar with a "Scanning..." message
4. Once connected, it will display your air quality data
5. Click the menu bar item to see detailed readings
6. Use the Refresh button to manually update readings

## Troubleshooting

- **Bluetooth permission denied**: Go to System Preferences > Security & Privacy > Bluetooth and enable access for Aranet4MenuBar
- **Device not found**: Make sure your Aranet4 is powered on and within range
- **Connection issues**: Try turning Bluetooth off and on in System Preferences

## Development

### Project Structure

```
Aranet4MenuBar/
├── main.swift                  # App entry point
├── AppDelegate.swift           # Application lifecycle
├── BluetoothManager.swift      # CoreBluetooth logic
├── Aranet4Data.swift           # Data models and decoder
├── StatusItemController.swift  # Menu bar management
├── MenuBarView.swift           # SwiftUI interface
├── Info.plist                  # App configuration
└── Aranet4MenuBar.entitlements # Sandbox permissions
```

### Building

```bash
./build.sh
```

This compiles the Swift files and creates a signed app bundle in `build/Aranet4MenuBar.app`.

### Protocol Details

The app uses the Aranet4 Bluetooth Low Energy GATT protocol:
- Service UUID: `f0cd1400-95da-4f4b-9ac8-aa55d312af0c`
- Current Readings: `f0cd1503-95da-4f4b-9ac8-aa55d312af0c`

Data format: CO2 (u16LE), Temperature (u16LE), Pressure (u16LE), Humidity (u8), Battery (u8)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Ideas for Contributions
- [ ] Add historical data graph
- [ ] Support for multiple Aranet4 devices
- [ ] Export data to CSV
- [ ] Custom alert thresholds
- [ ] Menu bar icon customization
- [ ] Temperature unit preference (°C/°F)

## Acknowledgments

- Aranet4 protocol documentation from [Aranet4-Python](https://github.com/Anrijs/Aranet4-Python)
- Built with Swift, SwiftUI, and CoreBluetooth

## License

MIT License - see [LICENSE](LICENSE) file for details
