# Lattice — build helpers.
#
# Everything here runs on macOS. The Swift package tests are the exception: VaultCore and
# MarkdownKit have no Metal or Realm dependency, so `make test-core` works anywhere Swift
# does, including Linux CI.

XCODEGEN := $(shell command -v xcodegen 2>/dev/null)
PACKAGE  := Packages/LatticeKit

.PHONY: bootstrap generate test test-core open clean

## Install tooling, generate the Xcode project, and open it.
bootstrap: generate open

## Generate Lattice.xcodeproj from project.yml.
generate:
ifndef XCODEGEN
	@echo "xcodegen not found. Install it with: brew install xcodegen"
	@exit 1
endif
	xcodegen generate
	@echo "Generated Lattice.xcodeproj"

## Run every package test (requires macOS for the GraphEngine suite).
test:
	swift test --package-path $(PACKAGE)

## Run only the platform-independent suites (no Metal, no Realm).
test-core:
	swift test --package-path $(PACKAGE) \
		--filter VaultCoreTests --filter MarkdownKitTests --filter VaultFilesTests

open:
	open Lattice.xcodeproj

clean:
	rm -rf Lattice.xcodeproj $(PACKAGE)/.build
