# Makefile for Go Coverage Examples
# Demonstrates native Go coverprofile plus converted formats.
#
# Build targets:
#   make test          - Run tests
#   make cover         - Generate native coverage.out
#   make lcov          - Convert coverprofile to LCOV
#   make cobertura     - Convert coverprofile to Cobertura XML
#   make html          - Generate HTML coverage report
#   make clean         - Remove build artifacts
#   make help          - Show this help message

GO = go
BUILD_DIR = build
COVERAGE_DIR = $(BUILD_DIR)/coverage
COVERPROFILE = $(BUILD_DIR)/coverage.out
LCOV_FILE = $(COVERAGE_DIR)/coverage.lcov
COBERTURA_FILE = $(COVERAGE_DIR)/coverage.xml
HTML_FILE = $(COVERAGE_DIR)/coverage.html

.PHONY: help test cover lcov cobertura html clean

help:
	@echo "Coverage Generation Examples - Go"
	@echo ""
	@echo "Available targets:"
	@echo "  make test          - Run go test"
	@echo "  make cover         - Generate native Go coverprofile (coverage.out)"
	@echo "  make lcov          - Convert coverage.out to LCOV report"
	@echo "  make cobertura     - Convert coverage.out to Cobertura XML"
	@echo "  make html          - Generate HTML coverage report"
	@echo "  make clean         - Clean build artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  $$ make cover      # Generate native Go coverage profile"
	@echo "  $$ make lcov       # Convert to LCOV format"
	@echo "  $$ make cobertura  # Convert to Cobertura XML (requires gocover-cobertura)"
	@echo ""

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(COVERAGE_DIR)

test:
	$(GO) test ./...

cover: $(BUILD_DIR)
	$(GO) test ./... -covermode=count -coverprofile=$(COVERPROFILE)
	@echo "✓ Go coverprofile generated: $(COVERPROFILE)"
	@echo ""
	@echo "Load in crazy-coverage.nvim:"
	@echo "  :CoverageLoad $(COVERPROFILE)"

lcov: cover
	@echo "Converting coverprofile to LCOV..."
	@command -v gcov2lcov >/dev/null 2>&1 || \
		(echo "gcov2lcov is required"; \
		 echo "Install with: go install github.com/jandelgado/gcov2lcov@latest"; \
		 exit 1)
	@GOROOT=$$($(GO) env GOROOT) gcov2lcov -infile=$(COVERPROFILE) -outfile=$(LCOV_FILE)
	@echo "✓ LCOV report generated: $(LCOV_FILE)"
	@echo ""
	@echo "Load in crazy-coverage.nvim:"
	@echo "  :CoverageLoad $(LCOV_FILE)"

cobertura: cover
	@echo "Converting coverprofile to Cobertura XML..."
	@command -v gocover-cobertura >/dev/null 2>&1 || \
		(echo "gocover-cobertura is required"; \
		 echo "Install with: go install github.com/boumenot/gocover-cobertura@latest"; \
		 exit 1)
	@gocover-cobertura < $(COVERPROFILE) > $(COBERTURA_FILE)
	@echo "✓ Cobertura XML report generated: $(COBERTURA_FILE)"
	@echo ""
	@echo "Load in crazy-coverage.nvim:"
	@echo "  :CoverageLoad $(COBERTURA_FILE)"

html: cover
	$(GO) tool cover -html=$(COVERPROFILE) -o $(HTML_FILE)
	@echo "✓ HTML report generated: $(HTML_FILE)"

clean:
	@rm -rf $(BUILD_DIR)
	@echo "✓ Build artifacts cleaned"
