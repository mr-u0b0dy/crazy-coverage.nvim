# Makefile for C++ Coverage Examples
# Demonstrates coverage generation with different tools
# 
# Build targets:
#   make gcov           - Build with GCC coverage (gcov)
#   make lcov           - Build with GCC coverage and generate LCOV report
#   make llvm           - Build with LLVM coverage
#   make llvm-report    - Build with LLVM and generate JSON report
#   make clean          - Remove build artifacts
#   make help           - Show this help message

CXX = g++
CXXFLAGS = -Wall -Wextra -g -O0 -std=c++11
LDFLAGS = 

# Build directory
BUILD_DIR = build
COVERAGE_DIR = $(BUILD_DIR)/coverage

# Source files
SOURCES = main.cpp math_utils.cpp
HEADERS = math_utils.hpp
OBJECTS = $(SOURCES:.cpp=.o)
TARGET = math_test

# GCC Coverage flags (gcov, lcov)
GCC_COVERAGE_FLAGS = --coverage -fprofile-arcs -ftest-coverage

# LLVM Coverage flags
LLVM_COVERAGE_FLAGS = -fprofile-instr-generate -fcoverage-mapping

.PHONY: help gcov lcov llvm llvm-report clean run

help:
	@echo "Coverage Generation Examples - C++"
	@echo ""
	@echo "Available targets:"
	@echo "  make gcov           - Build with GCC/gcov coverage"
	@echo "  make lcov           - Build and generate LCOV report"
	@echo "  make llvm           - Build with LLVM/clang coverage"
	@echo "  make llvm-report    - Build LLVM and generate JSON report"
	@echo "  make run            - Run the test program"
	@echo "  make clean          - Clean build artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  $$ make gcov        # Build with GCC coverage"
	@echo "  $$ make run         # Run and generate coverage data"
	@echo "  $$ make lcov        # Generate LCOV report (coverage.lcov)"
	@echo ""

# ===== GCC/gcov Coverage =====
gcov: CXXFLAGS += $(GCC_COVERAGE_FLAGS)
gcov: $(BUILD_DIR)/$(TARGET)
	@echo "✓ Built with GCC/gcov coverage support"
	@echo ""
	@echo "Run: cd $(BUILD_DIR) && ./$(TARGET)"
	@echo "Then: lcov --capture --directory . --output-file coverage.lcov"

# ===== GCC/LCOV Report =====
lcov: gcov run
	@echo ""
	@echo "Generating LCOV report..."
	@mkdir -p $(COVERAGE_DIR)
	cd $(BUILD_DIR) && lcov --capture --directory . --output-file coverage.lcov
	cd $(BUILD_DIR) && lcov --remove coverage.lcov '/usr/*' --output-file coverage.lcov
	cp $(BUILD_DIR)/coverage.lcov $(COVERAGE_DIR)/
	@echo "✓ LCOV report generated: $(COVERAGE_DIR)/coverage.lcov"
	@echo ""
	@echo "Load in crazy-coverage.nvim:"
	@echo "  :CoverageLoad $(COVERAGE_DIR)/coverage.lcov"

# ===== LLVM/clang Coverage =====
llvm: CXX = clang++
llvm: CXXFLAGS += $(LLVM_COVERAGE_FLAGS)
llvm: clean $(BUILD_DIR)/$(TARGET)
	@echo "✓ Built with LLVM/clang coverage support"
	@echo ""
	@echo "Run coverage:"
	@echo "  cd $(BUILD_DIR)"
	@echo "  LLVM_PROFILE_FILE=\"$(TARGET).profraw\" ./$(TARGET)"
	@echo ""
	@echo "Convert to JSON:"
	@echo "  llvm-profdata merge -o $(TARGET).profdata $(TARGET).profraw"
	@echo "  llvm-cov export -format=json ./$(TARGET) -instr-profile=$(TARGET).profdata > coverage.json"

# ===== LLVM/JSON Report =====
llvm-report: llvm run-llvm
	@echo ""
	@echo "Converting LLVM profile to JSON..."
	@mkdir -p $(COVERAGE_DIR)
	cd $(BUILD_DIR) && llvm-profdata merge -o $(TARGET).profdata $(TARGET).profraw
	cd $(BUILD_DIR) && llvm-cov export ./$(TARGET) -instr-profile=$(TARGET).profdata > coverage.json
	cp $(BUILD_DIR)/coverage.json $(COVERAGE_DIR)/
	@echo "✓ LLVM JSON report generated: $(COVERAGE_DIR)/coverage.json"
	@echo ""
	@echo "Load in crazy-coverage.nvim:"
	@echo "  :CoverageLoad $(COVERAGE_DIR)/coverage.json"

# ===== Build Rules =====
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/$(TARGET): $(BUILD_DIR) $(addprefix $(BUILD_DIR)/,$(OBJECTS))
	$(CXX) $(CXXFLAGS) -o $@ $(addprefix $(BUILD_DIR)/,$(OBJECTS)) $(LDFLAGS)

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# ===== Execution =====
run: $(BUILD_DIR)/$(TARGET)
	@echo "Running test program..."
	cd $(BUILD_DIR) && ./$(TARGET)
	@echo "✓ Program executed"

run-llvm: $(BUILD_DIR)/$(TARGET)
	@echo "Running test program with LLVM profiling..."
	cd $(BUILD_DIR) && LLVM_PROFILE_FILE="$(TARGET).profraw" ./$(TARGET)
	@echo "✓ LLVM profile generated"

# ===== Cleanup =====
clean:
	@rm -rf $(BUILD_DIR)
	@echo "✓ Build artifacts cleaned"

distclean: clean
	@echo "✓ All coverage data removed"
