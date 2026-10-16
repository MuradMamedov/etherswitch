# Contributing to EtherSwitch

## Building

Requirements: macOS 13+ and Xcode or the Command Line Tools (`xcode-select --install`). There are no third-party dependencies.

```sh
./build.sh           # builds build/EtherSwitch.app (universal: arm64 + x86_64, ad-hoc signed)
./build.sh install   # also copies it to ~/Applications and launches it
```

The Command Line Tools sometimes ship an SDK newer than their Swift compiler, which fails with *"this SDK is not supported by the compiler"*. `build.sh` detects this and falls back to the newest installed SDK that compiles. To force a specific SDK:

```sh
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk ./build.sh
```

The project is plain `swiftc` plus `Info.plist`, with no Xcode project or SwiftPM, so the build stays a single readable script.

## Project layout

| File | Purpose |
| --- | --- |
| `Sources/main.swift` | App delegate: wires up the switcher, the menu, wake notifications and `NWPathMonitor` |
| `Sources/Switcher.swift` | The state machine. Runs every check on a private serial queue and decides when to turn Wi-Fi on or off |
| `Sources/Net.swift` | Thin wrappers around `networksetup`, `ipconfig`, `ifconfig` and `curl` |
| `Sources/StatusMenu.swift` | Menu bar icon and menu (main thread only) |
| `Sources/Support.swift` | Log file with rotation, and the LaunchAgent used for Launch at Login |
| `build.sh` | Build, SDK fallback, universal binary, signing, local install |

## How detection works

A check runs every 5 seconds, 1 second after any `NWPathMonitor` path change, and 3 seconds after wake.

**Wired link.** Wired candidates are the hardware ports from `networksetup -listallhardwareports`, excluding Wi-Fi, Thunderbolt and bridge ports. A candidate is usable when `ifconfig` reports `status: active`, `ipconfig getifaddr` returns a non-link-local IPv4 address, and `ipconfig getoption <dev> router` returns a router.

If a previously usable link stops qualifying, it is reported down at once when the physical link is inactive (cable pulled), and otherwise only after a 10-second grace period, which rides out DHCP renewals.

**Internet verification.** Once Wi-Fi is off, `curl` fetches `http://captive.apple.com/hotspot-detect.html`:

- The first check waits 10s after the switch, so a VPN has time to reconnect.
- After a success, the next check is 30s later. After a failure, it's 5s later.
- Four consecutive failures turn Wi-Fi back on and suspend Ethernet for 5 minutes.

Limits are based on elapsed time, not on how many checks have run, so a burst of path-change events can't cause a false fallback.

**Ownership.** `wifiOffByUs` (persisted in `UserDefaults`) records whether EtherSwitch turned Wi-Fi off. Wi-Fi is only turned back on when this is set, so a user who turned Wi-Fi off by hand isn't overridden. When Ethernet is usable and Wi-Fi is already off, auto-switch claims ownership. Turning Wi-Fi on or off from the menu clears ownership and pauses auto-switch.

## Design decisions

- **Turning Wi-Fi off instead of changing the service order.** Service order rarely is the problem: VPN tunnels stay bound to the interface they connected over. Turning Wi-Fi off is the only switch that reliably moves them. It also needs no admin rights, while `-ordernetworkservices` does.
- **No router ping.** Sending traffic to LAN devices triggers macOS's Local Network privacy prompt. Until the user answers it, that traffic is blocked, and if they deny it, it stays blocked. The internet check already catches dead links, so EtherSwitch never touches the LAN.
- **Internet check not bound to the wired interface.** VPNs such as GlobalProtect drop traffic that bypasses the tunnel, so `curl --interface en7` fails even on a working link. While Wi-Fi is off, unbound traffic has to go over Ethernet anyway.
- **LaunchAgent instead of `SMAppService`.** It works for ad-hoc-signed apps in any location. The plist is rewritten on every launch, so it follows the app if it's moved. `KeepAlive.SuccessfulExit = false` restarts the app after a crash but not after Quit.

## Testing

There is no automated test suite yet. Extracting the decision logic in `Switcher.applyPolicy` into a pure function would make it unit-testable, and would be a welcome contribution.

Before opening a PR, run through this manually with `./build.sh install`, watching `~/Library/Logs/EtherSwitch.log`:

- [ ] Plug in Ethernet with Wi-Fi on: Wi-Fi turns off within a few seconds
- [ ] Unplug Ethernet: Wi-Fi turns on within ~5 seconds
- [ ] Cable connected to a router with no upstream internet: Wi-Fi comes back after ~25s and **Retry Ethernet Now** appears
- [ ] **Turn Wi-Fi On** from the menu while on Ethernet: Wi-Fi stays on and the icon dims
- [ ] Sleep and wake while on Ethernet: no spurious switches in the log
- [ ] Toggle **Launch at Login**: `~/Library/LaunchAgents/io.github.muradmamedov.EtherSwitch.plist` appears or disappears

## Releasing

1. Bump `CFBundleShortVersionString` (and `CFBundleVersion`) in `Info.plist`.
2. Commit, then tag and push:

   ```sh
   git tag v1.2.0 && git push origin v1.2.0
   ```

3. The [Build workflow](.github/workflows/build.yml) builds the app and attaches `EtherSwitch.zip` to a new GitHub Release with generated notes.

Releases are ad-hoc signed, not notarized. Notarization needs an Apple Developer ID. If one becomes available, add `codesign --options runtime` with that identity plus a `notarytool submit` step to the workflow.

## Command-line uninstall

```sh
pkill -x EtherSwitch
rm -rf ~/Applications/EtherSwitch.app ~/Library/LaunchAgents/io.github.muradmamedov.EtherSwitch.plist
defaults delete io.github.muradmamedov.EtherSwitch
rm -f ~/Library/Logs/EtherSwitch.log*
```
