 build_runner:
	dart run build_runner build --delete-conflicting-outputs

lint_fix:
	dart fix --apply && dart format --set-exit-if-changed .

# Run example with DevTools
run_with_devtools:
	@echo "Running example app with DevTools..."
	cd example && flutter run -d chrome --dart-define=flutter.inspector.structuredErrors=true

# Clean all build artifacts
clean_all:
	flutter clean
	cd example && flutter clean