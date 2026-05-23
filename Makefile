PROJECT := PalmPilot
XCODEPROJ := $(PROJECT).xcodeproj
SCHEME := $(PROJECT)
BUILD_SCRIPT := ./build-app.sh

.PHONY: all build build-release run clean help project xcbuild lint

all: build

# ── SPM Builds (default, no Xcode required) ──────────────────────────

build:
	@$(BUILD_SCRIPT) debug

build-release:
	@$(BUILD_SCRIPT) release

run: build
	@echo "==> Launching $(PROJECT)..."
	open .build/debug/$(PROJECT).app

clean:
	@echo "==> Cleaning..."
	rm -rf .build
	rm -rf build DerivedData
	rm -rf $(XCODEPROJ)

# ── Xcode workflow (requires Xcode + XcodeGen) ───────────────────────

project:
	@echo "==> Generating $(XCODEPROJ) with XcodeGen..."
	xcodegen --spec project.yml

open: project
	@echo "==> Opening $(XCODEPROJ)..."
	open $(XCODEPROJ)

xcbuild: project
	@echo "==> Building with Xcode..."
	xcodebuild -project $(XCODEPROJ) -scheme $(SCHEME) build

# ── Lint ─────────────────────────────────────────────────────────────

lint:
	@echo "==> Linting..."
	@if which swiftlint > /dev/null; then \
		swiftlint Sources/; \
	else \
		echo "swiftlint not installed. Install with: brew install swiftlint"; \
	fi

# ── Help ─────────────────────────────────────────────────────────────

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "SPM targets (no Xcode required):"
	@echo "  build          Build (debug) — default target"
	@echo "  build-release  Build (release)"
	@echo "  run            Build and launch .app"
	@echo "  clean          Remove all build artifacts"
	@echo ""
	@echo "Xcode targets (requires Xcode + XcodeGen):"
	@echo "  project        Generate .xcodeproj with XcodeGen"
	@echo "  open           Generate and open in Xcode"
	@echo "  xcbuild        Build with xcodebuild"
	@echo ""
	@echo "Other:"
	@echo "  lint           Run SwiftLint"
	@echo "  help           Show this message"
