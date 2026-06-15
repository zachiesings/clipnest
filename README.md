# ClipNest

A lightweight, private clipboard manager for macOS. Lives in your menu bar,
keeps a searchable history of what you copy, and lets you paste it back with a
click or a global hotkey (⌘⇧V).

**Privacy first** — everything stays local on your Mac. ClipNest does **not**
use Accessibility or keyboard monitoring, and nothing is ever sent anywhere.

## Features
- Menu-bar popover with your clipboard history (text & images)
- Global hotkey ⌘⇧V (via Carbon hotkeys — App Store compliant)
- Open at login (optional, off by default, via `SMAppService`)
- **ClipNest Pro** (one-time IAP): unlimited history, pinning, search, all themes

## Build
The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open ClipNest.xcodeproj
```

CI/CD: built & signed for the Mac App Store on Codemagic (`codemagic.yaml`),
signing via App Store Connect API key.

- Bundle ID: `app.clipnest.ClipNest`
- Minimum macOS: 13.0
