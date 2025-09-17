# Simple Production Email Test
# Run with: MIX_ENV=prod docker-compose exec app mix run test_prod_email_simple.exs

IO.puts "🧪 Simple Production Email Test"
IO.puts "=============================="

# Start the application
Application.ensure_all_started(:efl)

# Get some sample data
alias Efl.Dadi
alias Efl.Repo
import Ecto.Query

IO.puts "\n📊 Fetching Sample Data..."

# Get a few sample Dadi records
sample_dadis = 
  Dadi
  |> limit(3)
  |> Repo.all()

IO.puts "Found #{length(sample_dadis)} Dadi records"

# Create simple CSV data
csv_data = [
  "ID,Title,URL,Post Date,Phone",
  Enum.map(sample_dadis, fn dadi ->
    "#{dadi.id || ""},#{dadi.title || ""},#{dadi.url || ""},#{dadi.post_date || ""},#{dadi.phone || ""}"
  end)
] |> List.flatten() |> Enum.join("\n")

IO.puts "CSV data created (#{String.length(csv_data)} bytes)"

# Test email sending
IO.puts "\n📧 Testing Email Sending..."

# Create test email
email = %Swoosh.Email{
  to: [{"Test Recipient", "test@example.com"}],
  from: {"EFL System", "noreply@efl.local"},
  subject: "EFL Test Email - #{DateTime.utc_now() |> DateTime.to_string()}",
  text_body: """
  This is a test email from the EFL application.
  
  Sample Data:
  #{csv_data}
  
  Generated at: #{DateTime.utc_now() |> DateTime.to_string()}
  """,
  attachments: [
    %Swoosh.Attachment{
      filename: "dadi_data.csv",
      content_type: "text/csv",
      data: csv_data
    }
  ]
}

# Send email
case Efl.Mailer.deliver(email) do
  {:ok, result} ->
    IO.puts "✅ Email sent successfully!"
    IO.puts "Result: #{inspect(result)}"
  {:error, reason} ->
    IO.puts "❌ Email sending failed!"
    IO.puts "Error: #{inspect(reason)}"
end

IO.puts "\n✅ Test Complete!"
