# Email and Excel Testing Guide

This guide explains how to test email functionality and Excel file generation in the EFL application.

## Quick Start

Run the interactive test script:
```bash
./test_email_prod.sh
```

## Available Test Scripts

### 1. Full Test (`test_prod_email.exs`)
- Fetches sample Dadi records and reference categories
- Generates detailed Excel/CSV file with formatting
- Sends email with attachment
- Provides comprehensive output and error handling

### 2. Simple Test (`test_prod_email_simple.exs`)
- Fetches a few Dadi records
- Creates basic CSV file
- Sends simple email with attachment
- Minimal output, good for quick testing

### 3. Production Mode Test
- Runs the simple test in production environment
- Uses production configuration settings
- Good for testing actual production email setup

## Manual Execution

### Run Full Test
```bash
docker-compose exec app mix run test_prod_email.exs
```

### Run Simple Test
```bash
docker-compose exec app mix run test_prod_email_simple.exs
```

### Run in Production Mode
```bash
MIX_ENV=prod docker-compose exec app mix run test_prod_email_simple.exs
```

### Run with Custom Configuration
```bash
docker-compose exec app mix run -c test_email_config.exs test_prod_email.exs
```

## Email Configuration

### Current Setup
The application uses Swoosh with Mailgun adapter by default. Configuration is in:
- `config/mailgun.exs` - Mailgun settings
- `web/models/mailer.ex` - Email sending logic

### Environment Variables
Set these for production email:
```bash
export MAILGUN_API_KEY="your-mailgun-api-key"
export MAILGUN_DOMAIN="your-mailgun-domain"
export MAILGUN_RECIPIENT="your-email@example.com"
export MAILGUN_ALERT_RECIPIENT="alerts@your-domain.com"
```

### Testing with Different Email Providers

#### Gmail SMTP
1. Enable 2-factor authentication
2. Generate an app password
3. Update `test_email_config.exs` with Gmail settings
4. Run with custom config

#### MailHog (Local Testing)
1. Install MailHog: `go install github.com/mailhog/MailHog@latest`
2. Run MailHog: `MailHog`
3. Update `test_email_config.exs` with MailHog settings
4. Check emails at http://localhost:8025

## Test Data

The test scripts will:
1. Fetch up to 5 sample Dadi records from the database
2. Fetch all reference categories
3. Generate CSV/Excel file with the data
4. Send email with the file as attachment

## Troubleshooting

### Common Issues

1. **"Email sending failed"**
   - Check Mailgun API key and domain
   - Verify network connectivity
   - Check application logs

2. **"No data found"**
   - Ensure database has sample data
   - Run migrations: `docker-compose exec app mix ecto.migrate`
   - Check database connection

3. **"Configuration error"**
   - Verify email configuration files
   - Check environment variables
   - Ensure Swoosh dependencies are installed

### Debug Steps

1. Check application logs:
   ```bash
   docker-compose logs app
   ```

2. Test database connection:
   ```bash
   docker-compose exec app mix run -e "IO.inspect(Efl.Repo.all(Efl.Dadi) |> Enum.take(3))"
   ```

3. Test email configuration:
   ```bash
   docker-compose exec app mix run -e "IO.inspect(Application.get_env(:swoosh, :adapter))"
   ```

## Expected Output

### Successful Test
```
🧪 Testing Production Email and Excel Generation
================================================

📊 Fetching Sample Data...
Found 3 Dadi records
Found 5 reference categories

📈 Creating Excel Data...
Excel data prepared with 8 rows

📄 Generating Excel File...
Excel file created: /tmp/dadi_data_1234567890.csv (1024 bytes)

📧 Testing Email Sending...

🚀 Sending Email...
✅ Email sent successfully!
Result: {:ok, %Swoosh.Email{}}

🧹 Cleaned up temporary file: /tmp/dadi_data_1234567890.csv

✅ Production Email and Excel Test Complete!
```

### Failed Test
```
❌ Email sending failed!
Error: {:error, :invalid_credentials}
```

## Customization

### Modify Test Data
Edit the query in the test scripts to fetch different data:
```elixir
# Get more records
sample_dadis = Dadi |> limit(10) |> Repo.all()

# Get specific category
sample_dadis = Dadi |> where([d], d.ref_category_id == 1) |> limit(5) |> Repo.all()
```

### Modify Email Content
Update the email subject, body, or recipients in the test scripts.

### Modify Excel Format
Change the CSV generation logic to create different file formats or include additional data.

## Production Deployment

Before deploying to production:
1. Test email functionality thoroughly
2. Verify Mailgun configuration
3. Set up proper environment variables
4. Test with real email addresses
5. Monitor email delivery rates and errors

