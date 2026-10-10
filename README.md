# Toolbelt

A menu-bar app for macOS 14+ that holds small utilities ("modules"). Turn modules on in Settings; their controls show up when you click the menu-bar icon.

## Modules

- **Night Shift Forever**: keeps Night Shift on until you turn it off, with a warmth slider. It needs no permissions. It uses Apple's private CoreBrightness framework (the same approach as [Shifty](https://github.com/thompsonate/Shifty) and [nightlight](https://github.com/smudge/nightlight)), so Toolbelt can't ship on the Mac App Store.

## Build

You'll need Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
make run      # build, copy to /Applications, and launch
make project  # just generate Toolbelt.xcodeproj to open in Xcode
```

## Adding a module

1. Create a folder under `Toolbelt/Modules/`.
2. Write a class that conforms to `ToolbeltModule` (see `ToolbeltModule.swift`).
3. Add it to `ModuleRegistry.makeAll()`.
