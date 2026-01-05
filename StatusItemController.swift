import AppKit
import SwiftUI
import Combine

class StatusItemController: ObservableObject {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var bluetoothManager: BluetoothManager
    private var settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    init(bluetoothManager: BluetoothManager, settingsManager: SettingsManager) {
        self.bluetoothManager = bluetoothManager
        self.settingsManager = settingsManager

        print("Creating status item...")

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        print("Status item created: \(statusItem != nil)")

        if let button = statusItem.button {
            print("Setting up button...")
            button.title = "Air Quality"
            button.action = #selector(togglePanel)
            button.target = self
            print("Button title set to: \(button.title)")
        } else {
            print("ERROR: Status item button is nil!")
        }

        // Create borderless panel (no arrow/notch)
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovable = false
        panel.isReleasedWhenClosed = false

        // Use native material background
        let contentView = NSHostingView(
            rootView: MenuBarView(bluetoothManager: bluetoothManager, settingsManager: settingsManager)
                .background(VisualEffectView())
        )
        panel.contentView = contentView

        // Round all corners - MUST be set AFTER setting contentView
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 10
        panel.contentView?.layer?.masksToBounds = true

        // Subscribe to reading updates
        setupObservers()
    }

    private func setupObservers() {
        bluetoothManager.$currentReading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                self?.updateMenuBarTitle(with: reading)
            }
            .store(in: &cancellables)

        bluetoothManager.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateMenuBarTitle(with: self?.bluetoothManager.currentReading, status: status)
            }
            .store(in: &cancellables)

        settingsManager.$temperatureUnit
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarTitle(with: self?.bluetoothManager.currentReading)
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarTitle(with reading: Aranet4Reading?, status: ConnectionStatus? = nil) {
        guard let button = statusItem.button else { return }

        let currentStatus = status ?? bluetoothManager.connectionStatus

        switch currentStatus {
        case .disconnected:
            button.title = "❌ Disconnected"
        case .scanning:
            button.title = "🔍 Scanning..."
        case .connecting:
            button.title = "🔄 Connecting..."
        case .connected:
            if let reading = reading {
                // Change text color to red only when CO2 is critically high
                let title = reading.menuBarText(unit: settingsManager.temperatureUnit)
                if reading.co2 >= 1200 {
                    // High CO2 - red text
                    let attributes: [NSAttributedString.Key: Any] = [
                        .foregroundColor: NSColor.systemRed,
                        .font: NSFont.menuBarFont(ofSize: 0)
                    ]
                    button.attributedTitle = NSAttributedString(string: title, attributes: attributes)
                } else {
                    // Normal - default color
                    button.title = title
                }
            } else {
                button.title = "⏳ Reading..."
            }
        }
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button else { return }

        // Position panel flush against menu bar
        let buttonRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero

        let panelRect = NSRect(
            x: buttonRect.midX - panel.frame.width / 2,
            y: buttonRect.minY - panel.frame.height - 3,
            width: panel.frame.width,
            height: panel.frame.height
        )

        panel.setFrame(panelRect, display: true)
        panel.makeKeyAndOrderFront(nil)

        // Monitor clicks outside to close
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            if self?.panel.isVisible == true {
                self?.closePanel()
            }
        }
    }

    private func closePanel() {
        panel.orderOut(nil)
    }
}

// MARK: - Visual Effect View for native material background

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
