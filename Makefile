 build_runner:
	dart run build_runner build --delete-conflicting-outputs

lint_fix:
	dart fix --apply && dart format --set-exit-if-changed .

# DevTools Extension Commands
build_extension:
	@echo "Building DevTools extension..."
	cd extension/devtools && flutter build web --release

copy_extension:
	@echo "Copying extension to devtools directory..."
	dart run devtools_extensions build_and_copy --source=extension/devtools --dest=extension/devtools/build
	@echo "Copying to devtools_extensions directory..."
	@mkdir -p devtools_extensions/voo_logging_0.0.2
	@cp -r extension/devtools/build/web/* devtools_extensions/voo_logging_0.0.2/

validate_extension:
	@echo "Validating DevTools extension..."
	dart run devtools_extensions validate --package=.

# Build and deploy extension in one command
deploy_extension: build_extension copy_extension validate_extension
	@echo "DevTools extension deployed successfully!"

# All-in-one command to prepare DevTools extension
prepare_devtools:
	@echo "================================================="
	@echo "Preparing Voo Logger DevTools Extension"
	@echo "================================================="
	@echo ""
	@echo "Step 1: Cleaning previous builds..."
	@cd extension/devtools && flutter clean
	@echo ""
	@echo "Step 2: Getting dependencies..."
	@flutter pub get
	@cd extension/devtools && flutter pub get
	@echo ""
	@echo "Step 3: Building extension..."
	@cd extension/devtools && flutter build web --release --no-tree-shake-icons
	@echo ""
	@echo "Step 4: Copying to devtools directory..."
	@dart run devtools_extensions build_and_copy --source=extension/devtools --dest=extension/devtools/build || true
	@echo "Copying to devtools_extensions directory..."
	@mkdir -p devtools_extensions/voo_logging_0.0.2
	@cp -r extension/devtools/build/web/* devtools_extensions/voo_logging_0.0.2/
	@echo ""
	@echo "Step 5: Validating extension..."
	@dart run devtools_extensions validate --package=.
	@echo ""
	@echo "================================================="
	@echo "✅ DevTools extension is ready!"
	@echo "================================================="
	@echo ""
	@echo "To use the extension:"
	@echo "1. Run your app: cd example && flutter run -d chrome"
	@echo "2. Open DevTools"
	@echo "3. Go to Extensions tab"
	@echo "4. Enable 'voo_logger'"
	@echo "5. The 'Voo Logger' tab will appear"
	@echo ""

# Run example with DevTools
run_with_devtools:
	@echo "Running example app with DevTools..."
	cd example && flutter run -d chrome --dart-define=flutter.inspector.structuredErrors=true

# Clean all build artifacts
clean_all:
	flutter clean
	cd extension/devtools && flutter clean
	cd example && flutter clean
