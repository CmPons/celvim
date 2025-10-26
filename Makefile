# celvim Testing Framework Makefile
# Provides convenient test execution commands

.PHONY: test test-file test-fast test-watch clean test-unit test-integration clean-tests

# Run all tests
test:
	@echo "Running all celvim tests..."
	@NVIM_APPNAME=celvim3 nvim --headless --noplugins -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
	@echo "Exit code: $$?"

# Show help
help:
	@echo "celvim Testing Framework"
	@echo ""
	@echo "Available targets:"
	@echo "  test              - Run all tests"
	@echo "  help              - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make test"

# Default target
.DEFAULT_GOAL := help
