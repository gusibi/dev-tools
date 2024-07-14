macapp:
	sh build_macapp.sh
apk:
	flutter build apk --no-tree-shake-icons
	flutter build appbundle --no-tree-shake-icons