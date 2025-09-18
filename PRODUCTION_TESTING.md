# Production Testing Guide

This guide explains how to use the production testing scripts and tools for the EFL application.

## 🚀 Quick Start

### Run All Production Tests
```bash
./run_prod_tests.sh
```

### Run Specific Test Categories
```bash
# Data validation only
docker-compose exec app mix run -c prod_test_config.exs test/test_dadi_with_cached_html.exs

# Email testing only
./test_email_prod.sh

# Excel generation only
docker-compose exec app mix run -e "Efl.Xls.Dadi.create_xls(); IO.puts 'Excel file created'"
```

## 📋 Test Categories

### 1. Data Validation Tests
- **HTML Parsing**: Tests parsing of cached HTML data
- **Date Validation**: Verifies strict "yesterday only" date validation
- **Input Sanitization**: Ensures malicious input is rejected
- **Data Integrity**: Validates data consistency

### 2. Excel Generation Tests
- **File Creation**: Tests Excel file generation
- **Data Export**: Verifies data is properly exported
- **File Size Validation**: Ensures files have sufficient content
- **Cleanup**: Tests proper file cleanup

### 3. Email Functionality Tests
- **Configuration**: Validates email configuration
- **Email Creation**: Tests email structure creation
- **Attachment Handling**: Verifies Excel file attachments
- **Delivery Logic**: Tests email sending logic (without actual sending)

### 4. Production Simulation Tests
- **Database Queries**: Tests database performance with real data
- **End-to-End Flow**: Simulates complete production workflow
- **Data Flow**: Validates data from parsing to email delivery
- **Error Handling**: Tests error scenarios

### 5. Performance Tests
- **HTML Parsing Speed**: Measures parsing performance
- **Database Query Speed**: Tests database performance
- **Memory Usage**: Monitors memory consumption
- **Processing Time**: Measures overall processing time

### 6. Security Tests
- **Input Validation**: Tests against malicious input
- **XSS Prevention**: Validates XSS protection
- **SQL Injection**: Tests SQL injection prevention
- **Date Validation**: Tests date manipulation attempts

## 🔧 Configuration

### Production Test Configuration
The `prod_test_config.exs` file contains:
- Email testing settings
- Database configuration
- Performance test limits
- Security test parameters
- Excel generation settings

### Environment Variables
```bash
# Email testing
export TEST_EMAIL_RECIPIENT="test@example.com"
export TEST_EMAIL_FROM="noreply@efl.local"

# Database testing
export MIX_ENV=test

# Performance testing
export MAX_PROCESSING_TIME=30000
export MAX_MEMORY_USAGE=100000000
```

## 📊 Test Reports

### Generated Reports
- **Test Report**: `test_report_YYYYMMDD_HHMMSS.txt`
- **Log Files**: Application logs in `info.log`
- **Excel Files**: Test Excel files in project root

### Report Contents
- Test execution summary
- Performance metrics
- Security validation results
- Recommendations for production

## 🚨 Troubleshooting

### Common Issues

#### Database Connection Errors
```bash
# Check container status
docker-compose ps

# Restart containers
docker-compose restart

# Check database health
docker-compose exec mysql mysql -u root -ppassword -e "SHOW DATABASES;"
```

#### Email Configuration Issues
```bash
# Test email configuration
docker-compose exec app mix run -e "IO.inspect(Application.get_env(:efl, Efl.Mailer))"

# Check Mailgun configuration
docker-compose exec app mix run -e "IO.inspect(Application.get_env(:mailgun, :api_key))"
```

#### Excel Generation Issues
```bash
# Test Excel generation
docker-compose exec app mix run -e "Efl.Xls.Dadi.create_xls(); IO.puts 'Excel created'"

# Check file permissions
ls -la *.xlsx
```

### Debug Mode
```bash
# Run with debug output
MIX_ENV=test docker-compose exec app mix run -e "Logger.configure(level: :debug); [your test code]"
```

## 📈 Performance Benchmarks

### Expected Performance
- **HTML Parsing**: < 100ms for 100 items
- **Database Queries**: < 50ms for simple queries
- **Excel Generation**: < 2s for 1000 records
- **Email Creation**: < 100ms

### Memory Usage
- **Base Application**: ~50MB
- **HTML Parsing**: +10MB per 1000 items
- **Excel Generation**: +5MB per 1000 records
- **Email Processing**: +2MB per email

## 🔒 Security Considerations

### Input Validation
- All user input is validated
- XSS attempts are blocked
- SQL injection is prevented
- Date manipulation is restricted

### Data Protection
- Sensitive data is not logged
- Test data is cleaned up
- No production data is used in tests
- Email addresses are anonymized

## 📝 Best Practices

### Before Production Deployment
1. Run all production tests
2. Verify email configuration
3. Check database performance
4. Validate security measures
5. Review test reports

### Regular Testing
1. Run tests after code changes
2. Test with different data sets
3. Monitor performance metrics
4. Update test configurations
5. Review security tests

### Monitoring
1. Set up application monitoring
2. Monitor email delivery
3. Track Excel generation success
4. Watch for validation failures
5. Monitor performance metrics

## 🆘 Support

### Getting Help
- Check the test reports for detailed error information
- Review application logs for specific errors
- Verify Docker container status
- Check database connectivity
- Validate email configuration

### Common Commands
```bash
# View logs
docker-compose logs app

# Check container status
docker-compose ps

# Restart services
docker-compose restart

# Run specific test
docker-compose exec app mix run [test_file.exs]
```
