# EtherSwitch

**Plug in a cable, get Ethernet. Unplug it, get Wi-Fi back.**

EtherSwitch is a small menu bar app for macOS. When your Mac has a working wired connection, it turns Wi-Fi off so all your traffic goes over the cable. When the cable is unplugged or stops working, it turns Wi-Fi back on.

## Why you might need it

You plug your Mac into Ethernet, but video calls still stutter and downloads are still slow, because your Mac keeps using Wi-Fi.

This happens a lot with VPNs (GlobalProtect, Cisco AnyConnect, and others). A VPN stays on the connection it started on, so if it connected over Wi-Fi, it keeps using Wi-Fi even after you plug in a cable. The only reliable fix is to turn Wi-Fi off, and remember to turn it back on when you unplug. EtherSwitch does that for you.

## Features

- Switches to Ethernet automatically when a cable is plugged in
- Turns Wi-Fi back on as soon as you unplug, or if Ethernet has no internet
- Shows which connection you're on, right in the menu bar
- Lets you pause it or turn Wi-Fi on or off by hand
- Starts automatically when you log in
- Needs no admin password and no special permissions

Requires macOS 13 Ventura or later. Works on Apple Silicon and Intel Macs.

## Install

1. Download **EtherSwitch.zip** from the [latest release](../../releases/latest).
2. Unzip it and drag **EtherSwitch.app** into your **Applications** folder.
3. Open EtherSwitch.

The first time you open it, macOS will say it can't verify the developer, because EtherSwitch isn't distributed through the App Store. To allow it:

1. Click **Done** in that message.
2. Open **System Settings → Privacy & Security**.
3. Scroll down, find the message about EtherSwitch, and click **Open Anyway**.

You only need to do this once. EtherSwitch then appears in your menu bar and starts automatically each time you log in.

## Using EtherSwitch

### The menu bar icon

| Icon | Meaning |
| --- | --- |
| Cable connector | You're on Ethernet, and Wi-Fi is off |
| Wi-Fi bars | You're on Wi-Fi |
| Wi-Fi with a slash | No connection |
| Any icon, dimmed | Auto-switch is paused |

### The menu

Click the icon to see which Ethernet connection is active, whether Wi-Fi is on, and the last switch EtherSwitch made.

- **Auto-switch**: turns automatic switching on or off.
- **Turn Wi-Fi On / Off**: switch Wi-Fi by hand. This pauses auto-switch so EtherSwitch doesn't undo your choice. Turn **Auto-switch** back on when you're done.
- **Retry Ethernet Now**: appears when EtherSwitch has given up on Ethernet because it had no internet (see below). Click it to try again right away.
- **Check Now**: re-checks your connections immediately.
- **Launch at Login**: start EtherSwitch automatically when you log in.
- **Open Log**: shows a history of every switch.
- **Quit EtherSwitch**

## How it decides

- **Cable plugged in and connected:** Wi-Fi is turned off.
- **Cable unplugged:** Wi-Fi is turned back on within a few seconds.
- **Cable plugged in but no internet:** after about 25 seconds without internet, Wi-Fi is turned back on. EtherSwitch leaves Ethernet alone for 5 minutes, then tries it again.

If you turn Wi-Fi off yourself while you're not plugged in, EtherSwitch leaves it off.

## Troubleshooting

**Wi-Fi keeps coming back on while I'm plugged in.**
Click **Open Log**. If you see "No internet via …", your wired connection isn't reaching the internet. Check the cable or router. Some office networks also block the address EtherSwitch uses to test the connection (see the privacy question below).

**Wi-Fi doesn't turn off.**
Some Macs, especially ones managed by an employer, require an administrator password to turn Wi-Fi on or off. EtherSwitch can't change Wi-Fi on those Macs. To check, open **System Settings → Wi-Fi → Advanced** and look for **Require administrator authorization to turn Wi-Fi on or off**.

**I want Wi-Fi on for a while, even though I'm plugged in.**
Choose **Turn Wi-Fi On** from the menu. Auto-switch pauses until you turn it back on.

**Unplugging the cable and plugging it back in didn't bring my internet back.**
Click **Check Now**. If you use a VPN, give it a few seconds to reconnect over the new connection.

**Does EtherSwitch send my data anywhere?**
No. To test the internet connection, it loads Apple's test page `captive.apple.com`, the same page macOS uses to detect Wi-Fi login pages. It sends nothing else and collects nothing.

## Uninstall

1. Open the EtherSwitch menu and turn off **Launch at Login**.
2. Choose **Quit EtherSwitch**.
3. Drag **EtherSwitch.app** from Applications to the Trash.

## Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for build instructions and how the app works.

## License

[MIT](LICENSE)
