# EtherSwitch

A tiny macOS menu bar app that makes your Mac actually use Ethernet when it's plugged in: it turns Wi-Fi off while a wired connection has internet, and turns it back on when the cable is unplugged or stops working.

## Why

macOS prefers Ethernet over Wi-Fi in its service order, yet traffic often stays on Wi-Fi after you plug in a cable. The usual culprit is a VPN (GlobalProtect, Cisco AnyConnect, etc.): the tunnel stays bound to the interface it connected over. Turning Wi-Fi off forces everything—including the VPN—onto Ethernet.

## Install

**From a release:** download `EtherSwitch.zip` from [Releases](../../releases), unzip it, and move `EtherSwitch.app` to `~/Applications` or `/Applications`. The app is ad-hoc signed, not notarized, so the first time you open it either right-click → Open, or run:

```sh
xattr -d com.apple.quarantine /path/to/EtherSwitch.app
```

**From source** (needs Xcode or the Command Line Tools):

```sh
./build.sh install   # builds a universal binary, copies it to ~/Applications, launches it
```

On first launch EtherSwitch registers itself to start at login (toggle it from the menu). Requires macOS 13 or later. Toggling Wi-Fi uses `networksetup`, which doesn't need admin rights unless *Require administrator authorization to turn Wi-Fi on or off* is enabled.

## How it works

Every 5 seconds, and whenever the network changes or the Mac wakes:

| Situation | Action |
| --- | --- |
| A wired port has an active link, an IPv4 address and a router | Turn Wi-Fi off |
| Wi-Fi is off and `captive.apple.com` is unreachable for ~25s | Turn Wi-Fi back on and ignore Ethernet for 5 minutes |
| Cable unplugged (link inactive) | Turn Wi-Fi on immediately |
| Ethernet loses its IP address or router for 10s | Turn Wi-Fi on |

EtherSwitch only turns Wi-Fi back on if it was the one that turned it off, or if Wi-Fi was already off while Ethernet was up when auto-switch took over.

The internet check is intentionally not bound to the Ethernet interface, because many VPNs block traffic outside the tunnel. It runs every 30s once the connection is confirmed, and every 5s while it's failing. EtherSwitch never contacts devices on your local network, so macOS doesn't ask for Local Network permission.

## Menu

- Current Ethernet interface and IP, Wi-Fi state, and the last switch made
- **Auto-switch**: pause or resume automatic switching (the icon dims while paused)
- **Turn Wi-Fi On/Off**: manual override; pauses auto-switch so it doesn't undo you
- **Retry Ethernet Now**: shown while Ethernet is being ignored after a failed internet check
- **Check Now**, **Launch at Login**, **Open Log**, **Quit**

The menu bar icon shows a cable on Ethernet, Wi-Fi bars on Wi-Fi, and a slashed Wi-Fi icon when neither is connected.

## Logs

Switch events are logged to `~/Library/Logs/EtherSwitch.log`. The log rotates at 512 KB.

## Uninstall

```sh
pkill -x EtherSwitch
rm -rf ~/Applications/EtherSwitch.app ~/Library/LaunchAgents/io.github.muradmamedov.EtherSwitch.plist
defaults delete io.github.muradmamedov.EtherSwitch
```

## Troubleshooting

- **Build fails with "this SDK is not supported by the compiler"**: your Command Line Tools ship an SDK newer than their Swift compiler. `build.sh` falls back to older installed SDKs automatically. To force one, run `SDKROOT=/path/to/MacOSX.sdk ./build.sh`.
- **Wi-Fi keeps coming back on**: check the log. "No internet via …" means `captive.apple.com` wasn't reachable over Ethernet, for example because a firewall blocks it.

## License

[MIT](LICENSE)
