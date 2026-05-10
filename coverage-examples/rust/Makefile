# Makefile for Rust Coverage Examples
# Demonstrates coverage generation with multiple tools and output formats.
#
# Supported coverage tools:
#   - cargo-tarpaulin  (via `cargo tarpaulin`)
#   - cargo-llvm-cov   (via `cargo llvm-cov`)
#
# Supported output formats:
#   - LCOV       (for crazy-coverage.nvim)
#   - JSON       (for parsing and programmatic access)
#   - XML        (Cobertura format)
#   - Cobertura  (direct XML format)
#   - HTML       (interactive reports, llvm-cov only)
#
# All coverage files are stored in: target/coverage/
#
# Build targets:
#   Tarpaulin targets:
#     make tarpaulin-lcov       - Generate LCOV report with cargo-tarpaulin
#     make tarpaulin-json       - Generate JSON report with cargo-tarpaulin
#     make tarpaulin-xml        - Generate XML/Cobertura report with cargo-tarpaulin
#
#   LLVM-cov targets:
#     make llvm-cov-lcov        - Generate LCOV report with cargo-llvm-cov
#     make llvm-cov-json        - Generate JSON report with cargo-llvm-cov
#     make llvm-cov-html        - Generate HTML report with cargo-llvm-cov
#     make llvm-cov-cobertura   - Generate Cobertura XML report with cargo-llvm-cov
#
#   Utility targets:
#     make test                 - Run Rust tests
#     make clean                - Remove build and coverage artifacts
#     make help                 - Show this help message

CARGO = cargo
TARGET_COVERAGE_DIR = target/coverage

# Tarpaulin output files
TARPAULIN_LCOV = $(TARGET_COVERAGE_DIR)/coverage-tarpaulin.lcov
TARPAULIN_JSON = $(TARGET_COVERAGE_DIR)/coverage-tarpaulin.json
TARPAULIN_XML = $(TARGET_COVERAGE_DIR)/coverage-tarpaulin.xml

# LLVM-cov output files
LLVM_COV_LCOV = $(TARGET_COVERAGE_DIR)/coverage-llvm-cov.lcov
LLVM_COV_JSON = $(TARGET_COVERAGE_DIR)/coverage-llvm-cov.json
LLVM_COV_COBERTURA = $(TARGET_COVERAGE_DIR)/coverage-llvm-cov-cobertura.xml

.PHONY: help test clean tarpaulin-lcov tarpaulin-json tarpaulin-xml llvm-cov-lcov llvm-cov-json llvm-cov-html llvm-cov-cobertura

help:
	@echo "=========================================="
	@echo "  Rust Coverage Generation with Makefile"
	@echo "=========================================="
	@echo ""
	@echo "TARPAULIN TARGETS (cargo-tarpaulin):"
	@echo "  make tarpaulin-lcov       Generate LCOV report"
	@echo "  make tarpaulin-json       Generate JSON report"
	@echo "  make tarpaulin-xml        Generate XML/Cobertura report"
	@echo ""
	@echo "LLVM-COV TARGETS (cargo-llvm-cov):"
	@echo "  make llvm-cov-lcov        Generate LCOV report"
	@echo "  make llvm-cov-json        Generate JSON report"
	@echo "  make llvm-cov-html        Generate interactive HTML report"
	@echo "  make llvm-cov-cobertura   Generate Cobertura XML report"
	@echo ""
	@echo "UTILITY TARGETS:"
	@echo "  make test                 Run Rust tests"
	@echo "  make clean                Remove all build and coverage artifacts"
	@echo "  make help                 Show this help message"
	@echo ""
	@echo "PREREQUISITES:"
	@echo "  For tarpaulin targets:"
	@echo "    $$ cargo install cargo-tarpaulin"
	@echo ""
	@echo "  For llvm-cov targets:"
	@echo "    $$ cargo install cargo-llvm-cov"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  $$ make tarpaulin-lcov    # Generate target/coverage/coverage-tarpaulin.lcov"
	@echo "  $$ make llvm-cov-lcov     # Generate target/coverage/coverage-llvm-cov.lcov"
	@echo "  $$ make llvm-cov-html     # Generate target/llvm-cov/html/index.html"
	@echo ""
	@echo "OUTPUT LOCATION:"
	@echo "  All coverage reports are stored in: $(TARGET_COVERAGE_DIR)/"
	@echo ""
	@echo "LOAD IN CRAZY-COVERAGE.NVIM:"
	@echo "  :CoverageLoad $(TARGET_COVERAGE_DIR)/coverage-tarpaulin.lcov"
	@echo "  :CoverageLoad $(TARGET_COVERAGE_DIR)/coverage-llvm-cov.lcov"
	@echo ""

$(TARGET_COVERAGE_DIR):
	@mkdir -p $(TARGET_COVERAGE_DIR)

test:
	$(CARGO) test

clean:
	@rm -rf target
	@echo "✓ Build and coverage artifacts cleaned"

# ==============================================================================
# TARPAULIN TARGETS
# ==============================================================================

tarpaulin-lcov: $(TARGET_COVERAGE_DIR)
	@command -v cargo-tarpaulin >/dev/null 2>&1 || \
		(echo "❌ cargo-tarpaulin is required"; \
		echo "Install with: cargo install cargo-tarpaulin"; \
		exit 1)
	@echo "📊 Generating LCOV report with cargo-tarpaulin..."
	$(CARGO) tarpaulin --out Lcov --output-dir $(TARGET_COVERAGE_DIR)
	@if [ -f "$(TARGET_COVERAGE_DIR)/lcov.info" ]; then \
		mv "$(TARGET_COVERAGE_DIR)/lcov.info" "$(TARPAULIN_LCOV)"; \
	elif [ -f "$(TARGET_COVERAGE_DIR)/lcov" ]; then \
		mv "$(TARGET_COVERAGE_DIR)/lcov" "$(TARPAULIN_LCOV)"; \
	fi
	@echo "✓ LCOV report generated: $(TARPAULIN_LCOV)"

tarpaulin-json: $(TARGET_COVERAGE_DIR)
	@command -v cargo-tarpaulin >/dev/null 2>&1 || \
		(echo "❌ cargo-tarpaulin is required"; \
		echo "Install with: cargo install cargo-tarpaulin"; \
		exit 1)
	@echo "📊 Generating JSON report with cargo-tarpaulin..."
	$(CARGO) tarpaulin --out Json --output-dir $(TARGET_COVERAGE_DIR)
	@if [ -f "$(TARGET_COVERAGE_DIR)/coverage.json" ]; then \
		mv "$(TARGET_COVERAGE_DIR)/coverage.json" "$(TARPAULIN_JSON)"; \
	elif [ -f "$(TARGET_COVERAGE_DIR)/tarpaulin-report.json" ]; then \
		mv "$(TARGET_COVERAGE_DIR)/tarpaulin-report.json" "$(TARPAULIN_JSON)"; \
	fi
	@echo "✓ JSON report generated: $(TARPAULIN_JSON)"

tarpaulin-xml: $(TARGET_COVERAGE_DIR)
	@command -v cargo-tarpaulin >/dev/null 2>&1 || \
		(echo "❌ cargo-tarpaulin is required"; \
		echo "Install with: cargo install cargo-tarpaulin"; \
		exit 1)
	@echo "📊 Generating XML/Cobertura report with cargo-tarpaulin..."
	$(CARGO) tarpaulin --out Xml --output-dir $(TARGET_COVERAGE_DIR)
	@if [ -f "$(TARGET_COVERAGE_DIR)/cobertura.xml" ]; then \
		mv "$(TARGET_COVERAGE_DIR)/cobertura.xml" "$(TARPAULIN_XML)"; \
	fi
	@echo "✓ XML report generated: $(TARPAULIN_XML)"

# ==============================================================================
# LLVM-COV TARGETS
# ==============================================================================

llvm-cov-lcov: $(TARGET_COVERAGE_DIR)
	@command -v cargo-llvm-cov >/dev/null 2>&1 || \
		(echo "❌ cargo-llvm-cov is required"; \
		echo "Install with: cargo install cargo-llvm-cov"; \
		exit 1)
	@echo "📊 Generating LCOV report with cargo-llvm-cov..."
	$(CARGO) llvm-cov --lcov --output-path $(LLVM_COV_LCOV)
	@echo "✓ LCOV report generated: $(LLVM_COV_LCOV)"

llvm-cov-json: $(TARGET_COVERAGE_DIR)
	@command -v cargo-llvm-cov >/dev/null 2>&1 || \
		(echo "❌ cargo-llvm-cov is required"; \
		echo "Install with: cargo install cargo-llvm-cov"; \
		exit 1)
	@echo "📊 Generating JSON report with cargo-llvm-cov..."
	$(CARGO) llvm-cov --json --output-path $(LLVM_COV_JSON)
	@echo "✓ JSON report generated: $(LLVM_COV_JSON)"

llvm-cov-html: $(TARGET_COVERAGE_DIR)
	@command -v cargo-llvm-cov >/dev/null 2>&1 || \
		(echo "❌ cargo-llvm-cov is required"; \
		echo "Install with: cargo install cargo-llvm-cov"; \
		exit 1)
	@echo "📊 Generating HTML report with cargo-llvm-cov..."
	$(CARGO) llvm-cov --html
	@echo "✓ HTML report generated: target/llvm-cov/html/index.html"

llvm-cov-cobertura: $(TARGET_COVERAGE_DIR)
	@command -v cargo-llvm-cov >/dev/null 2>&1 || \
		(echo "❌ cargo-llvm-cov is required"; \
		echo "Install with: cargo install cargo-llvm-cov"; \
		exit 1)
	@echo "📊 Generating Cobertura XML report with cargo-llvm-cov..."
	$(CARGO) llvm-cov --cobertura --output-path $(LLVM_COV_COBERTURA)
	@echo "✓ Cobertura XML report generated: $(LLVM_COV_COBERTURA)"
