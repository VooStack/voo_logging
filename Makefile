build_runner:
	dart run build_runner build --delete-conflicting-outputs

lint_fix:
	dart fix --apply && dart format --set-exit-if-changed .

# DevTools Extension Commands
prepare_devtools:
	@echo "================================================="
	@echo "Preparing Voo Logger DevTools Extension"
	@echo "================================================="
	@echo ""
	@echo "Step 1: Cleaning previous builds..."
	@rm -rf devtools_extensions/
	@echo ""
	@echo "Step 2: Getting dependencies..."
	@flutter pub get
	@echo ""
	@echo "Step 3: Ensuring extension is available..."
	@echo "DevTools extension code is in lib/features/devtools_extension/"
	@echo ""
	@echo "================================================="
	@echo "✅ DevTools extension is ready!"
	@echo "================================================="
	@echo ""
	@echo "To use the extension:"
	@echo "1. Run your app: cd example && flutter run -d chrome"
	@echo "2. Open DevTools (press 'c' in terminal)"
	@echo "3. Navigate to Extensions tab"
	@echo "4. The 'Voo Logger' tab should appear automatically"
	@echo ""
	@echo "Note: The extension is embedded in the voo_logging package"
	@echo "and will be loaded automatically when your app uses it."
	@echo ""

# Run example with DevTools
run_with_devtools:
	@echo "Running example app with DevTools..."
	cd example && flutter run -d chrome --dart-define=flutter.inspector.structuredErrors=true

# Clean all build artifacts
clean_all:
	flutter clean
	cd example && flutter clean
	rm -rf devtools_extensions/