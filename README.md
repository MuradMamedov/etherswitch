# EtherSwitch

A macOS menu bar app that turns Wi-Fi off while Ethernet has internet, and back on when you unplug.

Useful when your Mac keeps using Wi-Fi after you plug in a cable. That's common with VPNs, which stay on the connection they started on.

## Install

1. Download **EtherSwitch.zip** from the [latest release](../../releases/latest), unzip it, and move **EtherSwitch.app** to **Applications**.
2. Open it. macOS will say it can't verify the developer. Click **Done**, then go to **System Settings → Privacy & Security** and click **Open Anyway**.

EtherSwitch starts automatically at login. Requires macOS 13 or later.

## How it works

- **Cable connected:** Wi-Fi turns off.
- **Cable unplugged:** Wi-Fi turns back on within a few seconds.
- **Cable connected but no internet:** Wi-Fi turns back on after about 25s, and Ethernet is retried 5 minutes later.

From the menu you can pause auto-switching, turn Wi-Fi on or off by hand (this pauses auto-switching), and view the log. The icon dims while auto-switching is paused.

## Troubleshooting

- **Wi-Fi keeps coming back on:** open the log from the menu. "No internet via …" means your wired connection can't reach the internet.
- **Wi-Fi doesn't turn off:** your Mac may require an admin password to change Wi-Fi. Check **System Settings → Wi-Fi → Advanced**.

To test the connection, EtherSwitch loads Apple's `captive.apple.com` test page. It collects no data.

## Uninstall

Turn off **Launch at Login** in the menu, quit EtherSwitch, and drag it to the Trash.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under [MIT](LICENSE).
