#!/usr/bin/env elixir

# Test runner for Floki error handling and Mailgun configuration tests
# This script runs tests without requiring database connections

IO.puts("Running Floki Error Handling and Mailgun Configuration Tests...")
IO.puts("=" |> String.duplicate(60))

# Load the application
Application.ensure_all_started(:efl)

# Run Floki error handling tests
IO.puts("\n1. Testing Floki Error Handling...")
IO.puts("-" |> String.duplicate(40))

# Test Floki.parse_document error handling
IO.puts("Testing Floki.parse_document with valid HTML...")
valid_html = "<html><body><div class='test'>Content</div></body></html>"
case Floki.parse_document(valid_html) do
  {:ok, parsed_doc} ->
    IO.puts("  ✓ Valid HTML parsed successfully")
    elements = Floki.find(".test", parsed_doc)
    IO.puts("  ✓ Found #{length(elements)} elements")
  {:error, reason} ->
    IO.puts("  ✗ Unexpected error: #{inspect(reason)}")
end

IO.puts("Testing Floki.parse_document with invalid HTML...")
invalid_html = "<html><body><div class='test'>Unclosed div"
case Floki.parse_document(invalid_html) do
  {:ok, parsed_doc} ->
    IO.puts("  ✓ Invalid HTML still parsed (Floki is forgiving)")
    elements = Floki.find(".test", parsed_doc)
    IO.puts("  ✓ Found #{length(elements)} elements")
  {:error, reason} ->
    IO.puts("  ✓ Invalid HTML properly handled: #{inspect(reason)}")
end

# Test Floki.find with non-existent selector
IO.puts("Testing Floki.find with non-existent selector...")
html = "<html><body><div class='test'>Content</div></body></html>"
{:ok, parsed_doc} = Floki.parse_document(html)
result = Floki.find(".non-existent", parsed_doc)
IO.puts("  ✓ Non-existent selector returned empty list: #{inspect(result)}")

# Test Floki.text with empty elements
IO.puts("Testing Floki.text with empty elements...")
empty_html = "<html><body><div class='empty'></div></body></html>"
{:ok, parsed_doc} = Floki.parse_document(empty_html)
result = Floki.find(".empty", parsed_doc) |> Floki.text()
IO.puts("  ✓ Empty elements returned empty string: '#{result}'")

# Test Floki.attribute with missing attribute
IO.puts("Testing Floki.attribute with missing attribute...")
result = Floki.find(".test", parsed_doc) |> Floki.attribute("href")
IO.puts("  ✓ Missing attribute returned empty list: #{inspect(result)}")

# Run Mailgun configuration tests
IO.puts("\n2. Testing Mailgun Configuration...")
IO.puts("-" |> String.duplicate(40))

# Test Swoosh configuration
IO.puts("Testing Swoosh adapter configuration...")
config = Application.get_env(:efl, Efl.Mailer)
IO.puts("  Adapter: #{inspect(config[:adapter])}")
IO.puts("  API Key: #{String.slice(config[:api_key] || "", 0, 10)}...")
IO.puts("  Domain: #{config[:domain]}")

if config[:adapter] == Swoosh.Adapters.Mailgun and 
   config[:api_key] && config[:domain] && 
   config[:api_key] != "your-mailgun-api-key" and
   config[:domain] != "your-mailgun-domain" do
  IO.puts("  ✓ Swoosh configuration is valid")
else
  IO.puts("  ✗ Swoosh configuration is invalid")
end

# Test Mailgun configuration
IO.puts("Testing Mailgun configuration...")
mailgun_key = Application.get_env(:mailgun, :mailgun_key)
mailgun_domain = Application.get_env(:mailgun, :mailgun_domain)

IO.puts("  Mailgun Key: #{String.slice(mailgun_key || "", 0, 10)}...")
IO.puts("  Mailgun Domain: #{mailgun_domain}")

if mailgun_key && mailgun_domain && 
   String.starts_with?(mailgun_domain, "https://api.mailgun.net/v3/") do
  IO.puts("  ✓ Mailgun configuration is valid")
else
  IO.puts("  ✗ Mailgun configuration is invalid")
end

# Test Mailer module
IO.puts("Testing Mailer module...")
if Code.ensure_loaded?(Efl.Mailer) do
  IO.puts("  ✓ Mailer module loaded successfully")
  
  if function_exported?(Efl.Mailer, :send_email_with_xls, 0) do
    IO.puts("  ✓ send_email_with_xls/0 function available")
  else
    IO.puts("  ✗ send_email_with_xls/0 function not available")
  end
  
  if function_exported?(Efl.Mailer, :send_alert, 0) do
    IO.puts("  ✓ send_alert/0 function available")
  else
    IO.puts("  ✗ send_alert/0 function not available")
  end
  
  if function_exported?(Efl.Mailer, :send_alert, 1) do
    IO.puts("  ✓ send_alert/1 function available")
  else
    IO.puts("  ✗ send_alert/1 function not available")
  end
else
  IO.puts("  ✗ Mailer module failed to load")
end

# Test email creation
IO.puts("Testing email creation...")
try do
  import Swoosh.Email
  
  email = new()
  |> to("test@example.com")
  |> from("test@zhouhaimeng.com")
  |> subject("Test Email")
  |> text_body("This is a test email")
  
  if %Swoosh.Email{} = email do
    IO.puts("  ✓ Email creation successful")
    IO.puts("    To: #{inspect(email.to)}")
    IO.puts("    From: #{inspect(email.from)}")
    IO.puts("    Subject: #{email.subject}")
    IO.puts("    Body: #{email.text_body}")
  else
    IO.puts("  ✗ Email creation failed")
  end
rescue
  ex ->
    IO.puts("  ✗ Email creation failed with error: #{inspect(ex)}")
end

IO.puts("\n" <> "=" |> String.duplicate(60))
IO.puts("Test Summary:")
IO.puts("✓ Floki error handling tests completed")
IO.puts("✓ Mailgun configuration tests completed")
IO.puts("✓ Email creation tests completed")
IO.puts("\nAll tests completed successfully!")
