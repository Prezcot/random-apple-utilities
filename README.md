# Toolbelt

A menu-bar app for macOS 14+ that holds small utilities ("modules"). Turn modules on in Settings; their controls show up when you click the menu-bar icon.

## Using it

- Click the menu-bar icon to open the panel. It shows the controls for the modules you've turned on, with tabs once two or more are on.
- Open Settings from the panel's footer button (or ⌘, while the panel is open), or by opening Toolbelt again from Finder or Spotlight. Toolbelt shows in the Dock only while Settings is open.
- On first launch, Settings opens with a welcome message and Toolbelt turns on Launch at login. You can switch it off in Settings.

## Modules

- **Night Shift Forever**: keeps Night Shift on until you turn it off, with a warmth slider. It needs no permissions.
  - **On**: sets Apple's Night Shift schedule so it always ends 11 to 12 hours from now, moves it on every hour, and turns Night Shift back on whenever macOS switches it off. After you quit Toolbelt, Night Shift stays on until that schedule ends.
  - **Off**: turns Night Shift off and sets the schedule to Off, so macOS doesn't turn it back on.
  - **Warmth**: drag the slider to preview the warmth, even while Night Shift is off. A warmth change made in System Settings shows up in the slider.
  - **Turning the module off** in Settings puts back the Night Shift setup you had before. Quitting Toolbelt leaves Night Shift as it is.

  It uses Apple's private CoreBrightness framework (the same approach as [Shifty](https://github.com/thompsonate/Shifty) and [nightlight](https://github.com/smudge/nightlight)), so Toolbelt can't ship on the Mac App Store.

## Build

You'll need Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
make run      # build, copy to /Applications, and launch
make project  # just generate Toolbelt.xcodeproj to open in Xcode
make icons    # redraw the app and menu-bar icons from scripts/make-icons.swift
```

`make build` runs `make icons` first, so edit the script rather than the files in `Toolbelt/Assets.xcassets`.

## Adding a module

1. Create a folder under `Toolbelt/Modules/`.
2. Write a class that conforms to `ToolbeltModule` (see `ToolbeltModule.swift`). Mark it `@Observable` so its panel updates when its state changes.
3. Add it to `ModuleRegistry.makeAll()`.

If the module needs a macOS permission, list it in `permissions`. Toolbelt asks for it when the module is turned on. Add new permissions to `ModulePermission.swift`.
