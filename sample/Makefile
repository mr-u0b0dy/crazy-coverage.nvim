# Makefile for coverage testing
CC = gcc
CFLAGS = -Wall -Wextra -g
COVERAGE_FLAGS = --coverage -fprofile-arcs -ftest-coverage

# LLVM coverage flags (alternative)
LLVM_COVERAGE_FLAGS = -fprofile-instr-generate -fcoverage-mapping

TARGET = math_test
SOURCES = main.c math_utils.c
OBJECTS = $(SOURCES:.c=.o)

# Default target with gcc coverage
all: clean coverage

# Build with gcc coverage support
coverage: CFLAGS += $(COVERAGE_FLAGS)
coverage: $(TARGET)
	@echo "Built with GCC coverage support"
	@echo "Run './$(TARGET)' to generate coverage data"

# Build with LLVM coverage support
llvm-coverage: CC = clang
llvm-coverage: CFLAGS += $(LLVM_COVERAGE_FLAGS)
llvm-coverage: clean $(TARGET)
	@echo "Built with LLVM coverage support"
	@echo "Run 'LLVM_PROFILE_FILE=\"math_test.profraw\" ./$(TARGET)' to generate coverage data"

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Run the program and generate coverage data
run: $(TARGET)
	@echo "Running program to generate coverage data..."
	./$(TARGET)
	@echo ""
	@echo "Coverage data generated!"

# Generate LCOV report (for gcc coverage)
lcov-report: run
	@echo "Generating LCOV report..."
	lcov --capture --directory . --output-file coverage.info
	lcov --remove coverage.info '/usr/*' --output-file coverage.info
	@echo "LCOV report generated: coverage.info"

# Generate HTML coverage report
html-report: lcov-report
	genhtml coverage.info --output-directory coverage_html
	@echo "HTML report generated in coverage_html/"

# Generate Cobertura XML report
cobertura-report: lcov-report
	@echo "Generating Cobertura XML report..."
	@which lcov_cobertura > /dev/null 2>&1 && \
		lcov_cobertura coverage.info -o coverage.xml && \
		echo "Cobertura report generated: coverage.xml" || \
		echo "lcov_cobertura not installed. Install with: pip install lcov_cobertura"

# Process LLVM coverage data
llvm-report:
	@echo "Processing LLVM coverage data..."
	llvm-profdata merge -sparse math_test.profraw -o math_test.profdata
	llvm-cov export ./$(TARGET) -instr-profile=math_test.profdata -format=lcov > coverage.lcov
	llvm-cov export ./$(TARGET) -instr-profile=math_test.profdata -format=text > coverage.json
	@echo "LLVM coverage reports generated"

# Clean build artifacts and coverage data
clean:
	rm -f $(TARGET) $(OBJECTS)
	rm -f *.gcda *.gcno *.gcov
	rm -f coverage.info coverage.xml coverage.lcov coverage.json
	rm -f *.profraw *.profdata
	rm -rf coverage_html

.PHONY: all coverage llvm-coverage run lcov-report html-report cobertura-report llvm-report clean
