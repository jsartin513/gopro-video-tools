# GoPro Video Tools Test Suite

This directory contains the test suite for the GoPro Video Tools bash toolkit.

## Test Framework

The test suite uses a custom TAP (Test Anything Protocol) compatible bash testing framework located in `test_framework.sh`. This provides:

- **Assertion functions**: `assert_success`, `assert_failure`, `assert_equals`, `assert_contains`
- **File system tests**: `assert_file_exists`, `assert_dir_exists`
- **Test organization**: `test_name`, `test_init`, `test_summary`
- **Setup/teardown**: Automatic cleanup between tests
- **Colored output**: Easy to read pass/fail status

## Running Tests

### Run All Tests
```bash
./tests/run_tests.sh
```

### Run Individual Test Files
```bash
./tests/test_workflow.sh
./tests/test_common.sh
./tests/test_config.sh
./tests/test_install.sh
./tests/test_utilities.sh
```

## Test Files

### `test_workflow.sh`
Tests the main `gopro_workflow.sh` script:
- Script existence and permissions
- Help and version functionality
- Command line argument parsing
- Error handling
- Mode selection features

### `test_common.sh`
Tests the shared utility functions in `common.sh`:
- Version management functions
- Logging functions (info, success, warning, error)
- Color constants

### `test_config.sh`
Tests the configuration system:
- Configuration file existence and format
- Configuration parsing and sourcing
- Default values and documentation

### `test_install.sh`
Tests the installation script:
- OS detection capabilities
- Dependency checking
- Platform-specific installation logic

### `test_utilities.sh`
Tests the utility scripts:
- Script existence and syntax validation
- Basic functionality checks
- Common patterns and best practices

## Test Results Interpretation

The test runner outputs in TAP format:
- `ok N - description` = Test passed
- `not ok N - description` = Test failed
- `# SKIP description - reason` = Test skipped
- Final summary shows total pass/fail counts

## Adding New Tests

1. Create a new test file: `test_newfeature.sh`
2. Source the test framework: `source test_framework.sh`
3. Define test functions with descriptive names
4. Use assertion functions to validate behavior
5. Call `test_init`, run your tests, and call `test_summary`

Example:
```bash
#!/bin/bash
source "$(dirname "$0")/test_framework.sh"

test_my_feature() {
    test_name "Feature works correctly"
    assert_success "my_command --test" "Command should succeed"
}

test_init
run_test test_my_feature
test_summary
```

## Test Fixtures

The `fixtures/` directory contains sample files for testing:
- `test_config.conf` - Sample configuration for testing
- `sample_games.jsonl` - Sample game data for testing

## Current Test Coverage

- ✅ **Core workflow functionality**
- ✅ **Configuration system**
- ✅ **Installation script**
- ✅ **Common utilities**
- ✅ **Script syntax validation**
- ⚠️ **Some utility script edge cases** (minor failures)
- ❌ **Integration testing** (planned)
- ❌ **Video processing** (requires test media files)

## Known Issues

Some tests may fail in certain environments:
1. **Missing dependencies**: Tests assume ffmpeg and other tools are available
2. **Platform differences**: Some tests may behave differently on different OS
3. **File permissions**: Ensure test scripts are executable (`chmod +x tests/*.sh`)

## Contributing

When adding new features to GoPro Video Tools:
1. Add corresponding tests
2. Ensure existing tests still pass
3. Update test documentation if needed
4. Consider adding integration tests for complex workflows
