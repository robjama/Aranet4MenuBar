# Quick Start Guide

## Running the App

The app has been built and is ready to use! Here's how to get started:

### Launch the App

```bash
cd ~/Aranet4MenuBar
open build/Aranet4MenuBar.app
```

Or simply double-click `Aranet4MenuBar.app` in the `build` folder.

### What to Expect

1. **First Launch**: macOS will ask for Bluetooth permission. Click "OK" to allow.

2. **Menu Bar Icon**: The app appears in your menu bar (top-right of screen):
   - "🔍 Scanning..." - Looking for your Aranet4
   - "🔄 Connecting..." - Found device, connecting
   - "CO2: 850 T: 22°C" - Connected and showing readings
   - "❌ Disconnected" - No connection

3. **Click the Menu Bar Item**: Shows a dropdown with:
   - Detailed readings (CO2, temperature, humidity, pressure, battery)
   - Color-coded CO2 level indicator
   - Last updated timestamp
   - Refresh button
   - Quit button

### Features

- **Auto-discovery**: Automatically finds and connects to your Aranet4
- **Auto-refresh**: Updates every 5 minutes
- **Manual refresh**: Click the Refresh button anytime
- **CO2 color coding**:
  - 🟢 Good: < 800 ppm
  - 🟡 Moderate: 800-1199 ppm
  - 🔴 Poor: ≥ 1200 ppm

### Troubleshooting

**App doesn't connect:**
- Make sure your Aranet4 is powered on
- Ensure it's within Bluetooth range (a few meters)
- Check Bluetooth is enabled in System Preferences
- Try turning your Aranet4 off and on

**Bluetooth permission denied:**
- Go to System Preferences > Security & Privacy > Bluetooth
- Enable access for Aranet4MenuBar

**To stop the app:**
- Click the menu bar item and select "Quit"
- Or use Activity Monitor to force quit

### Rebuilding

If you make changes to the code:

```bash
cd ~/Aranet4MenuBar
./build.sh
```

### Using Xcode (Recommended for Development)

For a better development experience with debugging:

1. Open Xcode
2. File > New > Project > macOS App
3. Follow instructions in README.md

## Next Steps

- The app will auto-launch when you open it
- It runs as a menu bar-only app (won't appear in Dock)
- Readings update automatically every 5 minutes
- Enjoy monitoring your air quality!
