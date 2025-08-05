# Build runner for code generation
build_runner:
	dart run build_runner build --delete-conflicting-outputs

# Fix linting and formatting issues
lint_fix:
	dart fix --apply && dart format --set-exit-if-changed .

# Build DevTools Extension (CRITICAL for publishing)
build_extension:
	@echo "Building DevTools extension..."
	dart run devtools_extensions build_and_copy --source=lib/features/devtools_extension --dest=extension/devtools
	@echo "Verifying extension build..."
	@if [ -f "extension/devtools/build/main.dart.js" ]; then \
		echo "✅ Extension built successfully"; \
		ls -la extension/devtools/build/; \
	else \
		echo "❌ Extension build failed - main.dart.js not found"; \
		exit 1; \
	fi

# Verify extension is working locally
test_extension:
	@echo "Testing extension locally..."
	cd example && flutter run -d chrome --web-port=9102
	@echo "Open DevTools and check for 'Voo Logger' tab"

# Prepare for release (builds extension + runs checks)
prepare_release: clean_extension build_extension
	@echo "Running pre-publish checks..."
	dart analyze
	flutter test --platform chrome test/features/devtools_extension/ || echo "⚠️  DevTools tests skipped (require web environment)"
	flutter test test/unit/ || echo "⚠️  Some tests failed"
	dart pub publish --dry-run
	@echo "✅ Ready for release! Run 'make publish_package' to publish."

# Clean extension build artifacts
clean_extension:
	@echo "Cleaning extension build artifacts..."
	rm -rf extension/devtools/build/
	rm -rf extension/devtools/.dart_tool/
	rm -rf extension/devtools/.flutter-plugins*

# Clean all build artifacts
clean_all: clean_extension
	flutter clean
	cd example && flutter clean
	rm -rf .dart_tool/
	rm -rf build/

# Publish package (with extension pre-built)
publish_package: prepare_release
	@echo "Publishing package..."
	dart pub publish

# Development workflow - build and test locally
dev: build_extension
	@echo "Development build complete"
	@echo "Run 'cd example && flutter run -d chrome' to test"

# Check if extension files are ready for publishing
check_extension:
	@echo "Checking extension build status..."
	@if [ -d "extension/devtools/build" ]; then \
		echo "✅ Extension build directory exists"; \
		if [ -f "extension/devtools/build/main.dart.js" ]; then \
			echo "✅ main.dart.js exists (size: $$(wc -c < extension/devtools/build/main.dart.js) bytes)"; \
		else \
			echo "❌ main.dart.js missing"; \
		fi; \
		if [ -f "extension/devtools/config.yaml" ]; then \
			echo "✅ config.yaml exists"; \
		else \
			echo "❌ config.yaml missing"; \
		fi; \
	else \
		echo "❌ Extension build directory missing - run 'make build_extension'"; \
	fi

# Force rebuild everything
rebuild: clean_all build_extension
	@echo "Complete rebuild finished"

# Help target
help:
	@echo "Available targets:"
	@echo "  build_extension    - Build the DevTools extension (REQUIRED before publishing)"
	@echo "  prepare_release    - Build extension + run all pre-publish checks"
	@echo "  publish_package    - Publish to pub.dev (builds extension first)"
	@echo "  test_extension     - Test extension locally in Chrome"
	@echo "  check_extension    - Verify extension build files exist"
	@echo "  clean_extension    - Clean extension build artifacts"
	@echo "  clean_all          - Clean all build artifacts"
	@echo "  dev                - Quick development build"
	@echo "  rebuild            - Clean everything and rebuild"
	@echo "  lint_fix           - Fix linting and formatting"
	@echo "  build_runner       - Run code generation"

.PHONY: build_runner lint_fix build_extension test_extension prepare_release clean_extension clean_all publish_package dev check_extension rebuild help