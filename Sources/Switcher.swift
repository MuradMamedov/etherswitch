import Foundation

struct SwitcherState {
    var wired: WiredLink?
    var wifiOn = false
    var wifiOffByUs = false
    var ethernetSuspendedUntil: Date?
    var lastAction: String?
}

final class Switcher {
    var onChange: ((SwitcherState) -> Void)?

    private let pollInterval: TimeInterval = 5
    private let wiredGracePeriod: TimeInterval = 10
    private let settleDelay: TimeInterval = 10
    private let verifyInterval: TimeInterval = 30
    private let verifyFailureLimit = 4
    private let suspendDuration: TimeInterval = 300

    private let queue = DispatchQueue(label: "EtherSwitch.Switcher")
    private let defaults = UserDefaults.standard

    private var wifiDevice: String?
    private var wifiOn = false
    private var lastWired: WiredLink?
    private var wiredDownSince: Date?
    private var nextInternetCheck = Date.distantPast
    private var verifyFailures = 0
    private var suspendedUntil: Date?
    private var lastAction: String?

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var autoEnabled: Bool {
        get { defaults.object(forKey: "autoEnabled") as? Bool ?? true }
        set {
            defaults.set(newValue, forKey: "autoEnabled")
            Log.write("auto-switch \(newValue ? "enabled" : "paused")")
            checkNow()
        }
    }

    // Persisted so a restart doesn't strand Wi-Fi off after the cable is pulled.
    private var wifiOffByUs: Bool {
        get { defaults.bool(forKey: "wifiOffByUs") }
        set { defaults.set(newValue, forKey: "wifiOffByUs") }
    }

    func start() {
        queue.async { [weak self] in self?.loop() }
    }

    func checkNow(after delay: TimeInterval = 0) {
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in self?.evaluate() }
    }

    func setWifiManually(on: Bool) {
        if autoEnabled { autoEnabled = false }
        queue.async { [weak self] in
            guard let self, let wifi = self.wifiDevice ?? Net.wifiDevice(in: Net.hardwarePorts()) else { return }
            Net.setWifiPower(wifi, on: on)
            self.wifiOffByUs = false
            self.record("Wi-Fi turned \(on ? "on" : "off") manually")
            self.evaluate()
        }
    }

    func retryEthernet() {
        queue.async { [weak self] in
            self?.suspendedUntil = nil
            self?.evaluate()
        }
    }

    private func loop() {
        evaluate()
        queue.asyncAfter(deadline: .now() + pollInterval) { [weak self] in self?.loop() }
    }

    private func evaluate() {
        let ports = Net.hardwarePorts()
        guard let wifi = Net.wifiDevice(in: ports) else { return }
        wifiDevice = wifi
        wifiOn = Net.wifiPower(wifi)
        let wired = detectWired(ports)

        if let until = suspendedUntil, until <= Date() { suspendedUntil = nil }
        if autoEnabled { applyPolicy(wired: wired, wifi: wifi) }

        let state = SwitcherState(
            wired: wired, wifiOn: wifiOn, wifiOffByUs: wifiOffByUs,
            ethernetSuspendedUntil: suspendedUntil, lastAction: lastAction)
        DispatchQueue.main.async { [weak self] in self?.onChange?(state) }
    }

    private func detectWired(_ ports: [HardwarePort]) -> WiredLink? {
        let probe = Net.probeWired(ports)
        if let link = probe.link {
            lastWired = link
            wiredDownSince = nil
            return link
        }
        guard let last = lastWired else { return nil }

        let downSince = wiredDownSince ?? Date()
        wiredDownSince = downSince
        if Net.linkActive(last.device) && Date().timeIntervalSince(downSince) < wiredGracePeriod {
            return last
        }
        Log.write("ethernet considered down: \(probe.failure)")
        lastWired = nil
        wiredDownSince = nil
        return nil
    }

    private func applyPolicy(wired: WiredLink?, wifi: String) {
        guard let link = wired else {
            if !wifiOn && wifiOffByUs {
                setWifi(wifi, on: true)
                record("Ethernet lost — Wi-Fi on")
            }
            return
        }
        guard suspendedUntil == nil else { return }

        if wifiOn {
            setWifi(wifi, on: false)
            verifyFailures = 0
            nextInternetCheck = Date().addingTimeInterval(settleDelay)
            record("Wi-Fi off — using \(link.name) (\(link.ip))")
            return
        }
        wifiOffByUs = true
        verifyInternet(via: link, wifi: wifi)
    }

    private func verifyInternet(via link: WiredLink, wifi: String) {
        guard Date() >= nextInternetCheck else { return }
        if Net.internetReachable() {
            verifyFailures = 0
            nextInternetCheck = Date().addingTimeInterval(verifyInterval)
            return
        }
        verifyFailures += 1
        nextInternetCheck = Date().addingTimeInterval(pollInterval)
        guard verifyFailures >= verifyFailureLimit else { return }

        setWifi(wifi, on: true)
        verifyFailures = 0
        suspendedUntil = Date().addingTimeInterval(suspendDuration)
        record("No internet via \(link.name) — Wi-Fi on, retrying Ethernet in \(Int(suspendDuration / 60)) min")
    }

    private func setWifi(_ device: String, on: Bool) {
        Net.setWifiPower(device, on: on)
        wifiOn = on
        wifiOffByUs = !on
    }

    private func record(_ message: String) {
        Log.write(message)
        lastAction = "\(Self.timeFormatter.string(from: Date()))  \(message)"
    }
}
