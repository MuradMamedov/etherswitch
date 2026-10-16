import Foundation

struct HardwarePort {
    let name: String
    let device: String
}

struct WiredLink: Equatable {
    let device: String
    let name: String
    let ip: String
}

enum Shell {
    @discardableResult
    static func run(_ path: String, _ args: [String]) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return (-1, "") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return (process.terminationStatus, output)
    }
}

enum Net {
    static func hardwarePorts() -> [HardwarePort] {
        let output = Shell.run("/usr/sbin/networksetup", ["-listallhardwareports"]).output
        var ports: [HardwarePort] = []
        var name: String?
        for line in output.split(separator: "\n") {
            if line.hasPrefix("Hardware Port: ") {
                name = String(line.dropFirst("Hardware Port: ".count))
            } else if line.hasPrefix("Device: "), let portName = name {
                ports.append(HardwarePort(name: portName, device: String(line.dropFirst("Device: ".count))))
                name = nil
            }
        }
        return ports
    }

    static func wifiDevice(in ports: [HardwarePort]) -> String? {
        ports.first { isWifi($0) }?.device
    }

    static func wiredCandidates(in ports: [HardwarePort]) -> [HardwarePort] {
        ports.filter { !isWifi($0) && !$0.name.hasPrefix("Thunderbolt") && !$0.device.hasPrefix("bridge") }
    }

    // No router ping: LAN traffic from the app needs macOS Local Network permission, and the internet check covers dead links.
    static func probeWired(_ ports: [HardwarePort]) -> (link: WiredLink?, failure: String) {
        var failure = "no wired interface with an IP"
        for port in wiredCandidates(in: ports) {
            guard let ip = ipv4(port.device) else { continue }
            guard router(port.device) != nil else {
                failure = "\(port.device) has no router"
                continue
            }
            guard linkActive(port.device) else {
                failure = "\(port.device) link inactive"
                continue
            }
            return (WiredLink(device: port.device, name: port.name, ip: ip), "")
        }
        return (nil, failure)
    }

    static func linkActive(_ device: String) -> Bool {
        Shell.run("/sbin/ifconfig", [device]).output.contains("status: active")
    }

    // Deliberately not bound to the wired interface: many VPNs drop traffic that bypasses the tunnel.
    static func internetReachable() -> Bool {
        let result = Shell.run("/usr/bin/curl", ["-s", "-m", "4", "http://captive.apple.com/hotspot-detect.html"])
        return result.status == 0 && result.output.contains("Success")
    }

    static func wifiPower(_ device: String) -> Bool {
        Shell.run("/usr/sbin/networksetup", ["-getairportpower", device]).output.hasSuffix("On")
    }

    static func setWifiPower(_ device: String, on: Bool) {
        Shell.run("/usr/sbin/networksetup", ["-setairportpower", device, on ? "on" : "off"])
    }

    private static func isWifi(_ port: HardwarePort) -> Bool {
        port.name == "Wi-Fi" || port.name == "AirPort"
    }

    private static func ipv4(_ device: String) -> String? {
        let result = Shell.run("/usr/sbin/ipconfig", ["getifaddr", device])
        guard result.status == 0, !result.output.isEmpty, !result.output.hasPrefix("169.254.") else { return nil }
        return result.output
    }

    private static func router(_ device: String) -> String? {
        let result = Shell.run("/usr/sbin/ipconfig", ["getoption", device, "router"])
        return result.status == 0 && !result.output.isEmpty ? result.output : nil
    }
}
