import Cocoa

final class StatusMenu: NSObject, NSMenuDelegate {
    private let switcher: Switcher
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var state = SwitcherState()

    init(switcher: Switcher) {
        self.switcher = switcher
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        updateIcon()
    }

    func update(_ newState: SwitcherState) {
        state = newState
        updateIcon()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbol: String
        if state.wired != nil && !state.wifiOn {
            symbol = "cable.connector"
        } else if state.wifiOn {
            symbol = "wifi"
        } else {
            symbol = "wifi.slash"
        }
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "EtherSwitch") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "ES"
        }
        button.appearsDisabled = !switcher.autoEnabled
        button.toolTip = switcher.autoEnabled ? "EtherSwitch" : "EtherSwitch (auto-switch paused)"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if let wired = state.wired {
            menu.addItem(info("Ethernet: \(wired.name) — \(wired.ip)"))
        } else {
            menu.addItem(info("Ethernet: not connected"))
        }
        if let until = state.ethernetSuspendedUntil {
            let minutes = max(1, Int(ceil(until.timeIntervalSinceNow / 60)))
            menu.addItem(info("Ethernet ignored (no internet) for \(minutes) more min"))
        }
        var wifiLine = "Wi-Fi: \(state.wifiOn ? "On" : "Off")"
        if !state.wifiOn && state.wifiOffByUs { wifiLine += " (by EtherSwitch)" }
        menu.addItem(info(wifiLine))
        if let last = state.lastAction { menu.addItem(info("Last: \(last)")) }

        menu.addItem(.separator())

        let auto = item("Auto-switch", #selector(toggleAuto))
        auto.state = switcher.autoEnabled ? .on : .off
        menu.addItem(auto)

        let manual = item(state.wifiOn ? "Turn Wi-Fi Off" : "Turn Wi-Fi On", #selector(toggleWifi))
        if switcher.autoEnabled { manual.toolTip = "Pauses auto-switch" }
        menu.addItem(manual)

        if state.ethernetSuspendedUntil != nil {
            menu.addItem(item("Retry Ethernet Now", #selector(retryEthernet)))
        }
        menu.addItem(item("Check Now", #selector(checkNow)))

        menu.addItem(.separator())

        let login = item("Launch at Login", #selector(toggleLogin))
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)
        menu.addItem(item("Open Log", #selector(openLog)))
        menu.addItem(item("Quit EtherSwitch", #selector(quit), key: "q"))
    }

    private func info(_ title: String) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        menuItem.isEnabled = false
        return menuItem
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        menuItem.target = self
        return menuItem
    }

    @objc private func toggleAuto() {
        switcher.autoEnabled.toggle()
        updateIcon()
    }

    @objc private func toggleWifi() {
        switcher.setWifiManually(on: !state.wifiOn)
        updateIcon()
    }

    @objc private func retryEthernet() { switcher.retryEthernet() }

    @objc private func checkNow() { switcher.checkNow() }

    @objc private func toggleLogin() { LoginItem.set(enabled: !LoginItem.isEnabled) }

    @objc private func openLog() { NSWorkspace.shared.open(Log.url) }

    @objc private func quit() { NSApp.terminate(nil) }
}
