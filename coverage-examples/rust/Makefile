# Makefile for Rust Coverage Examples
# Demonstrates coverage generation with cargo-tarpaulin.
#
# Build targets:
#   make test          - Run tests
#   make lcov          - Generate LCOV report via cargo tarpaulin
#   make clean         - Remove build artifacts
#   make help          - Show this help message

CARGO = cargo
BUILD_DIR = build
COVERAGE_DIR = $(BUILD_DIR)/coverage
LCOV_FILE = $(COVERAGE_DIR)/coverage.lcov

.PHONY: help test lcov clean

help:
	@echo "Coverage Generation Examples - Rust"
	@echo ""
	@echo "Available targets:"
	@echo "  make test          - Run Rust tests"
	@echo "  make lcov          - Generate LCOV report with cargo tarpaulin"
	@echo "  make clean         - Clean build artifacts"
	@echo ""
	@echo "Prerequisite:"
	@echo "  $$ cargo install cargo-tarpaulin"
	@echo ""
	@echo "Example:"
	@echo "  $$ make lcov       # Generate build/coverage/coverage.lcov"
	@echo ""

$(BUILD_DIR):
	@mkdir -p $(COVERAGE_DIR)

test:
	$(CARGO) test

lcov: $(BUILD_DIR)
	@command -v cargo-tarpaulin >/dev/null 2>&1 || \
		(echo "cargo-tarpaulin is required"; \
		echo "Install with: cargo install cargo-tarpaulin"; \
		exit 1)
	$(CARGO) tarpaulin --out Lcov --output-dir $(COVERAGE_DIR)
	@if [ -f "$(COVERAGE_DIR)/lcov.info" ]; then mv "$(COVERAGE_DIR)/lcov.info" "$(LCOV_FILE)"; fi
	@if [ -f "$(COVERAGE_DIR)/lcov" ]; then mv "$(COVERAGE_DIR)/lcov" "$(LCOV_FILE)"; fi
	@echo "✓ LCOV report generated: $(LCOV_FILE)"
	@echo ""
	@echo "Load in crazy-coverage.nvim:"
	@echo "  :CoverageLoad $(LCOV_FILE)"

clean:
	@rm -rf $(BUILD_DIR) target
	@echo "✓ Build artifacts cleaned"
