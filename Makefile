launcher_icon:
	dart run icons_launcher:create --path icons_launcher.yaml

build_runner:
	dart run build_runner build --delete-conflicting-outputs

lint_fix:
	dart fix --apply && dart format --set-exit-if-changed .
