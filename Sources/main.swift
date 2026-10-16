import Cocoa
import Network

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let switcher = Switcher()
    private let pathMonitor = NWPathMonitor()
    private var statusMenu: StatusMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LoginItem.registerOnFirstLaunch()

        let menu = StatusMenu(switcher: switcher)
        statusMenu = menu
        switcher.onChange = { [weak menu] state in menu?.update(state) }

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)

        pathMonitor.pathUpdateHandler = { [weak self] _ in self?.switcher.checkNow(after: 1) }
        pathMonitor.start(queue: DispatchQueue(label: "EtherSwitch.PathMonitor"))

        Log.write("started (auto=\(switcher.autoEnabled))")
        switcher.start()
    }

    @objc private func didWake() {
        switcher.checkNow(after: 3)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
