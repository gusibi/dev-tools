rm DEVTools.dmg
rm rw.DEVTools.dmg

flutter build macos

create-dmg \
  --volname "DEV Tools" \
  --window-pos 200 120 \
  --window-size 800 1000 \
  --icon-size 100 \
  --hide-extension "Dev Tools.app" \
  --app-drop-link 600 185 \
  "DEVTools.dmg" \
  "./build/macos/Build/Products/Release/Dev Tools.app"