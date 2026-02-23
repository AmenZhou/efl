# IEx Console Test - Copy and paste this into the running IEx console
# Or run: MIX_ENV=prod iex -S mix -e "Code.eval_file(\"iex_console_test.exs\")"

IO.puts "🧪 IEx Console Test - Date Validation"
IO.puts "===================================="

# Test the date validation logic
alias Efl.Dadi
alias Efl.TimeUtil

IO.puts "\n📅 Testing Date Validation Logic..."

# Get yesterday's date (target date)
target_date = TimeUtil.target_date()
IO.puts "Target date (yesterday): #{target_date}"

# Test 1: Valid date (yesterday) - should be valid
IO.puts "\n✅ Test 1: Valid date (yesterday)"
attrs_yesterday = %{
  title: "Test Post Yesterday",
  url: "http://test.com/yesterday",
  post_date: target_date,
  ref_category_id: 1,
  phone: nil,
  content: nil
}

changeset_yesterday = Dadi.changeset(%Dadi{}, attrs_yesterday)
if changeset_yesterday.valid? do
  IO.puts "✅ PASS: Yesterday's date is valid"
else
  IO.puts "❌ FAIL: Yesterday's date should be valid"
  IO.puts "Errors: #{inspect(changeset_yesterday.errors)}"
end

# Test 2: Invalid date (2 days ago) - should be invalid
IO.puts "\n❌ Test 2: Invalid date (2 days ago)"
two_days_ago = target_date |> Timex.shift(days: -2)
attrs_old = %{
  title: "Test Post Old",
  url: "http://test.com/old",
  post_date: two_days_ago,
  ref_category_id: 1,
  phone: nil,
  content: nil
}

changeset_old = Dadi.changeset(%Dadi{}, attrs_old)
if not changeset_old.valid? do
  IO.puts "✅ PASS: Old date is correctly rejected"
  IO.puts "Error: #{inspect(changeset_old.errors[:post_date])}"
else
  IO.puts "❌ FAIL: Old date should be invalid"
end

# Test 3: Future date - should be invalid
IO.puts "\n❌ Test 3: Future date"
tomorrow = target_date |> Timex.shift(days: 1)
attrs_future = %{
  title: "Test Post Future",
  url: "http://test.com/future",
  post_date: tomorrow,
  ref_category_id: 1,
  phone: nil,
  content: nil
}

changeset_future = Dadi.changeset(%Dadi{}, attrs_future)
if not changeset_future.valid? do
  IO.puts "✅ PASS: Future date is correctly rejected"
  IO.puts "Error: #{inspect(changeset_future.errors[:post_date])}"
else
  IO.puts "❌ FAIL: Future date should be invalid"
end

IO.puts "\n📡 Proxy connectivity check (proxies table)..."

# Use a proxy from the proxies table and check connectivity
try do
  case Efl.Proxy.check_connectivity() do
    {:ok, proxy_info, body} ->
      IO.puts "✅ Proxy connectivity OK"
      IO.puts "   Proxy: #{inspect(proxy_info.ip)}:#{inspect(proxy_info.port)} (id: #{proxy_info.id})"
      IO.puts "   Response: #{inspect(body)}"
    {:error, reason} ->
      IO.puts "❌ Proxy connectivity FAIL: #{inspect(reason)}"
  end
rescue
  e -> IO.puts "❌ Proxy check error: #{inspect(e)}"
end

# Optional: check against dadi site (same as production) - same short timeout
IO.puts "\n🔗 Proxy check vs dadi360 (optional, 15s timeout)..."
try do
  case Efl.Proxy.check_connectivity(url: "http://c.dadi360.com/", timeout_ms: 15_000) do
    {:ok, _info, _body} ->
      IO.puts "✅ Proxy can reach c.dadi360.com"
    {:error, reason} ->
      IO.puts "⚠️  Proxy could not reach dadi: #{inspect(reason)}"
  end
rescue
  e -> IO.puts "⚠️  Dadi check error: #{inspect(e)}"
end

IO.puts "\n📡 Testing API and Category Processing (max 60s to avoid stuck test)..."

# Long-running: API fetch + create_items. Run in a task with timeout so script doesn't hang.
task = Task.async(fn ->
  # Fetch from API
  IO.puts "\n🔍 Fetching from API..."
  try do
    result = Efl.Proxy.fetch_from_api
    IO.puts "✅ API fetch result: #{inspect(result)}"
  rescue
    error -> IO.puts "⚠️  API fetch error: #{inspect(error)}"
  end

  # Test category processing
  cat = %Efl.RefCategory{
    name: "STORE_RENT",
    display_name: "店铺转让",
    url: "/27.page",
    page_size: 2,
    id: 1
  }
  IO.puts "\n📝 Creating items for category: #{cat.display_name}"
  try do
    result = Efl.Dadi.Category.create_items(cat)
    IO.puts "✅ Category processing result: #{inspect(result)}"
  rescue
    error -> IO.puts "⚠️  Category processing error: #{inspect(error)}"
  end
end)

try do
  Task.await(task, 60_000)
catch
  :exit, {:timeout, _} ->
    IO.puts "⚠️  API/Category section timed out after 60s (script continues)"
end

IO.puts "\n🎯 Summary:"
IO.puts "Date validation is now limited to yesterday only (days_diff != 0)"
IO.puts "Proxy connectivity uses 15s timeout; API/Category section has 60s max."
IO.puts "\n✅ IEx console test completed!"
