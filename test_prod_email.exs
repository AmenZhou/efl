# Test Production Email and Excel Generation
# Run with: docker-compose exec app mix run test_prod_email.exs

# Ensure all required modules are loaded
Code.require_file("web/models/dadi.ex", __DIR__)
Code.require_file("web/models/ref_category.ex", __DIR__)
Code.require_file("web/models/mailer.ex", __DIR__)

alias Efl.Dadi
alias Efl.RefCategory
alias Efl.Mailer
alias Efl.Repo
import Ecto.Query

IO.puts "🧪 Testing Production Email and Excel Generation"
IO.puts "================================================"

# Start the application if not already started
unless Process.whereis(Efl.Repo) do
  IO.puts "Starting application..."
  Application.ensure_all_started(:efl)
end

IO.puts "\n📊 Fetching Sample Data..."

# Get a few sample Dadi records
sample_dadis = 
  Dadi
  |> limit(5)
  |> Repo.all()

IO.puts "Found #{length(sample_dadis)} Dadi records"

# Get reference categories
ref_categories = 
  RefCategory
  |> Repo.all()

IO.puts "Found #{length(ref_categories)} reference categories"

# Create Excel data
IO.puts "\n📈 Creating Excel Data..."

# Prepare data for Excel
excel_data = [
  ["ID", "Title", "URL", "Post Date", "Phone", "Content Preview", "Category"],
  ["", "", "", "", "", "", ""]  # Empty row for spacing
]

# Add sample Dadi records
Enum.each(sample_dadis, fn dadi ->
  # Find the category name
  category_name = case Enum.find(ref_categories, fn cat -> cat.id == dadi.ref_category_id end) do
    nil -> "Unknown"
    cat -> cat.name
  end
  
  # Truncate content for preview
  content_preview = case dadi.content do
    nil -> ""
    content when is_binary(content) -> 
      if String.length(content) > 50 do
        String.slice(content, 0, 50) <> "..."
      else
        content
      end
    _ -> ""
  end
  
  # Format post date
  post_date_str = case dadi.post_date do
    nil -> ""
    date when is_struct(date, Date) -> Date.to_string(date)
    date when is_struct(date, NaiveDateTime) -> 
      date |> NaiveDateTime.to_date() |> Date.to_string()
    _ -> ""
  end
  
  row = [
    to_string(dadi.id || ""),
    dadi.title || "",
    dadi.url || "",
    post_date_str,
    dadi.phone || "",
    content_preview,
    category_name
  ]
  
  excel_data = excel_data ++ [row]
end)

# Add summary row
excel_data = excel_data ++ [
  ["", "", "", "", "", "", ""],  # Empty row
  ["Summary", "", "", "", "", "", ""],
  ["Total Records", to_string(length(sample_dadis)), "", "", "", "", ""],
  ["Categories", to_string(length(ref_categories)), "", "", "", "", ""],
  ["Generated At", DateTime.to_string(DateTime.utc_now()), "", "", "", "", ""]
]

IO.puts "Excel data prepared with #{length(excel_data)} rows"

# Create Excel file content (CSV format for simplicity)
IO.puts "\n📄 Generating Excel File..."

csv_content = 
  excel_data
  |> Enum.map(fn row ->
    row
    |> Enum.map(fn cell ->
      # Escape quotes and wrap in quotes if contains comma
      cell_str = to_string(cell)
      if String.contains?(cell_str, ",") or String.contains?(cell_str, "\"") do
        "\"#{String.replace(cell_str, "\"", "\"\"")}\""
      else
        cell_str
      end
    end)
    |> Enum.join(",")
  end)
  |> Enum.join("\n")

# Write to file
filename = "dadi_data_#{DateTime.utc_now() |> DateTime.to_unix()}.csv"
filepath = "/tmp/#{filename}"
File.write!(filepath, csv_content)
IO.puts "Excel file created: #{filepath} (#{String.length(csv_content)} bytes)"

# Test email sending
IO.puts "\n📧 Testing Email Sending..."

# Create test email
email_subject = "EFL Data Export Test - #{DateTime.utc_now() |> DateTime.to_string()}"
email_body = """
This is a test email from the EFL application.

Data Summary:
- Total Dadi records: #{length(sample_dadis)}
- Reference categories: #{length(ref_categories)}
- Generated at: #{DateTime.utc_now() |> DateTime.to_string()}

The attached CSV file contains the sample data.

This is an automated test email. Please ignore if received in production.
"""

# Read the file content for attachment
file_content = File.read!(filepath)

# Create email with attachment
email = %Swoosh.Email{
  to: [{"Test Recipient", "test@example.com"}],
  from: {"EFL System", "noreply@efl.local"},
  subject: email_subject,
  html_body: email_body |> String.replace("\n", "<br>"),
  text_body: email_body,
  attachments: [
    %Swoosh.Attachment{
      filename: filename,
      content_type: "text/csv",
      data: file_content
    }
  ]
}

IO.puts "Email prepared with attachment: #{filename}"

# Send email
IO.puts "\n🚀 Sending Email..."

case Mailer.deliver(email) do
  {:ok, result} ->
    IO.puts "✅ Email sent successfully!"
    IO.puts "Result: #{inspect(result)}"
  {:error, reason} ->
    IO.puts "❌ Email sending failed!"
    IO.puts "Error: #{inspect(reason)}"
end

# Clean up temporary file
File.rm!(filepath)
IO.puts "\n🧹 Cleaned up temporary file: #{filepath}"

IO.puts "\n✅ Production Email and Excel Test Complete!"
IO.puts "============================================="
IO.puts "Summary:"
IO.puts "- Fetched #{length(sample_dadis)} Dadi records"
IO.puts "- Fetched #{length(ref_categories)} reference categories"
IO.puts "- Generated CSV file with #{length(excel_data)} rows"
IO.puts "- Attempted to send email with attachment"
IO.puts "\nCheck your email configuration and logs for delivery status."
