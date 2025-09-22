# Simple Email Test - Send to configured alert recipient
# Run with: MIX_ENV=prod mix run test_email_simple.exs

IO.puts "🧪 Simple Email Test - Production Mode"
IO.puts "======================================"

# Start the application
Application.ensure_all_started(:efl)

# Get the configured alert recipient
alert_recipient = Application.get_env(:mailgun, :alert_recipient)
IO.puts "Sending test email to: #{alert_recipient}"

# Create a simple test email
email = %Swoosh.Email{
  to: [{"Test Recipient", alert_recipient}],
  from: {"EFL System", "noreply@zhouhaimeng.com"},
  subject: "EFL Test Email - #{DateTime.utc_now() |> DateTime.to_string()}",
  text_body: """
  This is a test email from the EFL application.
  
  Test Details:
  - Time: #{DateTime.utc_now() |> DateTime.to_string()}
  - Environment: Production
  - Server: Running on port 4000
  
  If you receive this email, the email system is working correctly!
  """,
  attachments: [
    %Swoosh.Attachment{
      filename: "test_data.csv",
      content_type: "text/csv",
      data: "ID,Title,URL,Date\n1,Test Item,http://example.com,#{Date.utc_today()}"
    }
  ]
}

IO.puts "\n📧 Sending test email..."

# Send email
case Efl.Mailer.deliver(email) do
  {:ok, result} ->
    IO.puts "✅ Email sent successfully!"
    IO.puts "Result: #{inspect(result)}"
    IO.puts "\n📬 Please check your email inbox: #{alert_recipient}"
  {:error, reason} ->
    IO.puts "❌ Email sending failed!"
    IO.puts "Error: #{inspect(reason)}"
end

IO.puts "\n✅ Test Complete!"
