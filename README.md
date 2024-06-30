# dev_tools

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application that follows the
[simple app state management
tutorial](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple).

For help getting started with Flutter development, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Assets

The `assets` directory houses images, fonts, and any other files you want to
include with your application.

The `assets/images` directory contains [resolution-aware
images](https://flutter.dev/docs/development/ui/assets-and-images#resolution-aware).

## Localization

This project generates localized messages based on arb files found in
the `lib/src/localization` directory.

To support additional languages, please visit the tutorial on
[Internationalizing Flutter
apps](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)


build macOS app

```bash
flutter build macos

create-dmg \
  --volname "DEV Tools" \
  --window-pos 200 120 \
  --window-size 800 1000 \
  --icon-size 100 \
  --icon "DEVTools.app" 200 190 \
  --hide-extension "DEVTools.app" \
  --app-drop-link 600 185 \
  "DEVTools.dmg" \
  "build/macos/Build/Products/Release/dev_tools.app"
```

create-dmg \
  --volname "DEV Tools" \
  --window-pos 200 120 \
  --window-size 800 1000 \
  --icon-size 100 \
  --hide-extension "Dev Tools.app" \
  --app-drop-link 600 185 \
  "DEVTools.dmg" \
  "./build/macos/Build/Products/Release/Dev Tools.app"