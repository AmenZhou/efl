# Test script that utilizes the cached HTML file
# Run with: mix run test_dadi_with_cached_html.exs

IO.puts "🧪 Testing Dadi Parsing with Cached HTML"
IO.puts "========================================"

# Start the application
Application.ensure_all_started(:efl)

alias Efl.HtmlParsers.Dadi.Category
alias Efl.Dadi, as: DadiModel
alias Efl.RefCategory
alias Efl.Repo

# Check if cached HTML file exists
if File.exists?("test/cached_html.html") do
  IO.puts "✅ Found cached HTML file"
  
  # Read cached HTML
  cached_html = File.read!("test/cached_html.html")
  IO.puts "📄 Cached HTML size: #{String.length(cached_html)} bytes"
  
  # Update HTML to use yesterday's date for validation
  yesterday = Efl.TimeUtil.target_date() |> Timex.format!("%m/%d/%Y", :strftime)
  updated_html = String.replace(cached_html, "01/15/2025", yesterday)
  IO.puts "📅 Updated HTML to use yesterday's date: #{yesterday}"
  
  # Test finding raw items
  IO.puts "\n🔍 Testing HTML parsing..."
  {:ok, items} = Category.find_raw_items({:ok, updated_html})
  IO.puts "Found #{length(items)} items in cached HTML"
  
  if length(items) > 0 do
    # Test parsing each item
    IO.puts "\n📊 Testing data extraction..."
    parsed_items = Enum.map(items, fn item ->
      %Category{
        title: Category.get_title(item),
        url: "http://c.dadi360.com" <> Category.get_link(item),
        post_date: Category.get_date(item),
        phone: ""
      }
    end)
    
    # Display parsed data
    Enum.with_index(parsed_items, 1) |> Enum.each(fn {item, index} ->
      IO.puts "\nItem #{index}:"
      IO.puts "  Title: #{item.title}"
      IO.puts "  URL: #{item.url}"
      IO.puts "  Date: #{inspect(item.post_date)}"
      IO.puts "  Phone: #{item.phone}"
    end)
    
    # Test database operations
    IO.puts "\n💾 Testing database operations..."
    
    # Create test ref category
    ref_category = %RefCategory{
      name: "test_category",
      display_name: "Test Category",
      page_size: 5
    } |> Repo.insert!()
    
    IO.puts "Created ref category: #{ref_category.display_name}"
    
    # Test database insertion
    valid_insertions = 0
    invalid_insertions = 0
    
    Enum.each(parsed_items, fn item ->
      dadi_params = %{item | ref_category_id: ref_category.id}
      |> Map.from_struct()
      
      changeset = DadiModel.changeset(%DadiModel{}, dadi_params)
      
      case Repo.insert(changeset) do
        {:ok, dadi} -> 
          valid_insertions = valid_insertions + 1
          IO.puts "✅ Inserted dadi record: #{dadi.title}"
        {:error, changeset} -> 
          invalid_insertions = invalid_insertions + 1
          IO.puts "❌ Failed to insert: #{inspect(changeset.errors)}"
      end
    end)
    
    IO.puts "\n📈 Database insertion results:"
    IO.puts "  Valid insertions: #{valid_insertions}"
    IO.puts "  Invalid insertions: #{invalid_insertions}"
    
    # Test Excel generation
    IO.puts "\n📊 Testing Excel generation..."
    Efl.Xls.Dadi.create_xls()
    file_name = Efl.Xls.Dadi.file_name()
    
    if File.exists?(file_name) do
      file_size = File.stat!(file_name).size
      IO.puts "✅ Excel file created: #{file_name} (#{file_size} bytes)"
      
      if file_size > 1000 do
        IO.puts "✅ Excel file has sufficient data"
      else
        IO.puts "⚠️  Excel file is small (might be empty)"
      end
      
      # Clean up
      File.rm!(file_name)
      IO.puts "🧹 Cleaned up Excel file"
    else
      IO.puts "❌ Excel file was not created"
    end
    
    # Test email sending logic (without actually sending)
    IO.puts "\n📧 Testing email sending logic..."
    
    # Create a test Excel file
    Efl.Xls.Dadi.create_xls()
    file_name = Efl.Xls.Dadi.file_name()
    
    if File.exists?(file_name) do
      file_size = File.stat!(file_name).size
      
      if file_size > 1000 do
        IO.puts "✅ Email would be sent (file has data)"
      else
        IO.puts "⚠️  Email would be skipped (file too small)"
      end
      
      # Clean up
      File.rm!(file_name)
    end
    
    # Clean up database
    Repo.delete_all(DadiModel)
    Repo.delete_all(RefCategory)
    IO.puts "🧹 Cleaned up database"
    
  else
    IO.puts "❌ No items found in cached HTML"
  end
  
else
  IO.puts "❌ Cached HTML file not found"
  IO.puts "Please ensure test/cached_html.html exists in the project root"
end

IO.puts "\n✅ Test Complete!"
