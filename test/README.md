# EFL Test Suite

This directory contains comprehensive tests for the EFL (Elixir Phoenix) application, focusing on error handling improvements and configuration validation.

## Test Files

### 1. Floki Error Handling Tests
- **File**: `test/support/floki_error_handling_test.exs`
- **Purpose**: Tests robust error handling in HTML parsing using Floki
- **Coverage**:
  - `Floki.parse_document/1` error handling
  - `Floki.find/2` with non-existent selectors
  - `Floki.text/1` with empty elements
  - `Floki.attribute/2` with missing attributes
  - Category parser error handling (`get_title/1`, `get_link/1`, `parse_date/1`)
  - Post parser error handling

### 2. Mailgun Configuration Tests
- **File**: `test/support/mailgun_configuration_test.exs`
- **Purpose**: Validates Mailgun email configuration and functionality
- **Coverage**:
  - Swoosh adapter configuration validation
  - Mailgun API key and domain validation
  - Email creation and structure validation
  - Environment variable fallback testing

### 3. Test Runner Script
- **File**: `test/run_error_handling_tests.exs`
- **Purpose**: Standalone test runner that works without database connections
- **Usage**: `MIX_ENV=prod mix run test/run_error_handling_tests.exs`

## Running Tests

### Quick Test (Recommended)
```bash
# Run the comprehensive test suite
MIX_ENV=prod mix run test/run_error_handling_tests.exs
```

### Individual Test Files
```bash
# Run Floki error handling tests
MIX_ENV=prod mix test test/support/floki_error_handling_test.exs

# Run Mailgun configuration tests
MIX_ENV=prod mix test test/support/mailgun_configuration_test.exs
```

### Full Test Suite
```bash
# Run all tests (requires database)
MIX_ENV=prod mix test
```

## Test Coverage

### Floki Error Handling
- ✅ **HTML Parsing**: Valid and invalid HTML handling
- ✅ **Element Selection**: Non-existent selectors
- ✅ **Text Extraction**: Empty elements and missing content
- ✅ **Attribute Access**: Missing attributes
- ✅ **Parser Functions**: Category and post parser error handling
- ✅ **Logging**: Warning messages for parsing errors

### Mailgun Configuration
- ✅ **Swoosh Adapter**: Proper configuration validation
- ✅ **API Credentials**: Key and domain format validation
- ✅ **Email Creation**: Basic and attachment email structures
- ✅ **Environment Variables**: Fallback configuration testing
- ✅ **Module Loading**: Mailer module availability

## Error Handling Improvements

### Before
- `Floki.parse_document` could crash the application
- Missing error handling in HTML parsing functions
- No graceful degradation for malformed HTML
- Swoosh configuration errors caused application crashes

### After
- Comprehensive error handling with try/rescue blocks
- Graceful degradation with sensible defaults
- Proper logging of parsing errors
- Robust configuration validation
- Application continues running despite parsing errors

## Test Results

The test suite validates:
1. **Floki Error Handling**: All HTML parsing functions handle errors gracefully
2. **Mailgun Configuration**: Email functionality is properly configured
3. **Application Stability**: Server continues running despite parsing errors
4. **Logging**: Errors are properly logged for debugging

## Maintenance

### Adding New Tests
1. Add test cases to appropriate test files
2. Update the test runner script if needed
3. Ensure tests work without database connections
4. Document new test coverage

### Running Tests in CI/CD
```bash
# In your CI/CD pipeline
MIX_ENV=prod mix run test/run_error_handling_tests.exs
```

### Debugging Failed Tests
1. Check application configuration
2. Verify dependencies are installed
3. Review error logs in `info.log`
4. Test individual components separately

## Dependencies

- **Floki**: HTML parsing library
- **Swoosh**: Email library
- **ExUnit**: Testing framework
- **Elixir 1.17.3**: Runtime environment

## Notes

- Tests are designed to run without database connections
- All tests use production configuration (`MIX_ENV=prod`)
- Error handling tests focus on robustness, not functionality
- Configuration tests validate setup without sending actual emails
