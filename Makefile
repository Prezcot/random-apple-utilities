# Uses Xcode directly, so `xcode-select` can stay pointed at the Command Line Tools.
DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
export DEVELOPER_DIR

APP := build/Build/Products/Release/Toolbelt.app

.PHONY: project build install run clean

project:
	xcodegen generate

build: project
	xcodebuild -project Toolbelt.xcodeproj -scheme Toolbelt -configuration Release \
		-derivedDataPath build -quiet build

install: build
	-osascript -e 'quit app "Toolbelt"'
	rm -rf /Applications/Toolbelt.app
	cp -R $(APP) /Applications/

run: install
	open /Applications/Toolbelt.app

clean:
	rm -rf build Toolbelt.xcodeproj Toolbelt/Info.plist
