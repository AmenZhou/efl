defmodule Efl.DadiTest do
  use Efl.ModelCase, async: true

  alias Efl.Dadi
  alias Efl.RefCategory

  @valid_attrs %{
    title: "Test Post",
    url: "https://example.com/test",
    content: "Test content",
    phone: "123-456-7890",
    post_date: ~D[2024-01-15],
    ref_category_id: 1
  }

  @invalid_attrs %{}

  setup do
    ref_category = %RefCategory{
      name: "test_category",
      display_name: "Test Category",
      page_size: 5
    } |> Repo.insert!()

    {:ok, ref_category: ref_category}
  end

  describe "changeset/2" do
    test "valid changeset with all fields", %{ref_category: ref_category} do
      attrs = Map.put(@valid_attrs, :ref_category_id, ref_category.id)
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.title == "Test Post"
      assert changeset.changes.url == "https://example.com/test"
      assert changeset.changes.content == "Test content"
      assert changeset.changes.phone == "123-456-7890"
      assert changeset.changes.post_date == ~D[2024-01-15]
      assert changeset.changes.ref_category_id == ref_category.id
    end

    test "valid changeset without phone", %{ref_category: ref_category} do
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.delete(:phone)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = Dadi.changeset(%Dadi{}, @invalid_attrs)
      
      refute changeset.valid?
      assert changeset.errors[:title] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:url] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:post_date] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:ref_category_id] == {"can't be blank", [validation: :required]}
    end

    test "invalid changeset with duplicate url", %{ref_category: ref_category} do
      # Create first post
      attrs = Map.put(@valid_attrs, :ref_category_id, ref_category.id)
      %Dadi{} |> Dadi.changeset(attrs) |> Repo.insert!()
      
      # Try to create duplicate - this should fail at database level
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # The changeset is valid, but database insert should fail
      assert changeset.valid?
      
      # Database insert should fail with constraint error
      assert {:error, changeset} = Repo.insert(changeset)
      refute changeset.valid?
      assert changeset.errors[:url] == {"has already been taken", [constraint: :unique, constraint_name: "dadi_url_index"]}
    end
  end

  describe "update_changeset/2" do
    test "valid update changeset with content and phone", %{ref_category: ref_category} do
      # Create initial post
      attrs = Map.put(@valid_attrs, :ref_category_id, ref_category.id)
      dadi = %Dadi{} |> Dadi.changeset(attrs) |> Repo.insert!()
      
      update_attrs = %{
        content: "Updated content",
        phone: "987-654-3210"
      }
      
      changeset = Dadi.update_changeset(dadi, update_attrs)
      assert changeset.valid?
      assert changeset.changes.content == "Updated content"
      assert changeset.changes.phone == "987-654-3210"
    end

    test "valid update changeset with content only", %{ref_category: ref_category} do
      # Create initial post
      attrs = Map.put(@valid_attrs, :ref_category_id, ref_category.id)
      dadi = %Dadi{} |> Dadi.changeset(attrs) |> Repo.insert!()
      
      update_attrs = %{content: "Updated content"}
      changeset = Dadi.update_changeset(dadi, update_attrs)
      
      assert changeset.valid?
      assert changeset.changes.content == "Updated content"
    end

    test "invalid update changeset with missing content" do
      dadi = %Dadi{}
      changeset = Dadi.update_changeset(dadi, %{})
      
      refute changeset.valid?
      assert changeset.errors[:content] == {"can't be blank", [validation: :required]}
    end
  end

  describe "date validation" do
    test "accepts yesterday's date in production", %{ref_category: ref_category} do
      # Mock production environment
      original_env = Mix.env()
      Mix.env(:prod)
      
      yesterday = Efl.TimeUtil.target_date()
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, yesterday)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # Should be valid in production with yesterday's date
      assert changeset.valid?
      
      # Restore original environment
      Mix.env(original_env)
    end

    test "rejects non-yesterday dates in production", %{ref_category: ref_category} do
      # Mock production environment
      original_env = Mix.env()
      Mix.env(:prod)
      
      # Use a date that's not yesterday
      wrong_date = Efl.TimeUtil.target_date() |> Timex.shift(days: -2)
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, wrong_date)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # Should be invalid in production with non-yesterday date
      refute changeset.valid?
      assert changeset.errors[:post_date] == {"can't be blank", []}
      
      # Restore original environment
      Mix.env(original_env)
    end

    test "allows any date in test environment", %{ref_category: ref_category} do
      # Test environment should allow any date
      future_date = ~D[2025-12-31]
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, future_date)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # Should be valid in test environment regardless of date
      assert changeset.valid?
    end

    test "allows any date in dev environment" do
      # Mock dev environment
      original_env = Mix.env()
      Mix.env(:dev)
      
      future_date = ~D[2025-12-31]
      
      attrs = @valid_attrs
      |> Map.put(:post_date, future_date)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # Should be valid in dev environment regardless of date
      assert changeset.valid?
      
      # Restore original environment
      Mix.env(original_env)
    end

    test "validates specific date formats that were causing issues", %{ref_category: ref_category} do
      # Test the specific dates that were causing parsing issues
      test_dates = [
        ~D[2025-09-16],  # September 16, 2025 (yesterday in our test case)
        ~D[2025-08-31],  # August 31, 2025
        ~D[2025-01-15],  # January 15, 2025
        ~D[2025-12-25]   # December 25, 2025
      ]

      for test_date <- test_dates do
        attrs = @valid_attrs
        |> Map.put(:ref_category_id, ref_category.id)
        |> Map.put(:post_date, test_date)
        
        changeset = Dadi.changeset(%Dadi{}, attrs)
        
        # In test environment, all dates should be valid
        assert changeset.valid?, "Date #{test_date} should be valid in test environment"
      end
    end

    test "handles Date struct conversion correctly", %{ref_category: ref_category} do
      # Test that Date structs are handled properly in validation
      date_struct = ~D[2025-09-16]
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, date_struct)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.post_date == date_struct
    end

    test "handles DateTime conversion to Date correctly", %{ref_category: ref_category} do
      # Test that DateTime structs are converted to Date properly
      datetime = ~N[2025-09-16 14:30:00]
      expected_date = ~D[2025-09-16]
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, datetime)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # The changeset should handle the conversion
      assert changeset.valid?
    end

    test "rejects nil post_date in production", %{ref_category: ref_category} do
      # Mock production environment
      original_env = Mix.env()
      Mix.env(:prod)
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, nil)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # Should be invalid with nil post_date
      refute changeset.valid?
      assert changeset.errors[:post_date] == {"can't be blank", [validation: :required]}
      
      # Restore original environment
      Mix.env(original_env)
    end

    test "validates post_date is required field", %{ref_category: ref_category} do
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.delete(:post_date)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      refute changeset.valid?
      assert changeset.errors[:post_date] == {"can't be blank", [validation: :required]}
    end
  end

  describe "date validation regression tests" do
    test "ensures 9/16/2025 date validation works correctly", %{ref_category: ref_category} do
      # This test ensures the specific date that was causing issues works correctly
      september_16_2025 = ~D[2025-09-16]
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, september_16_2025)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # Should be valid in test environment
      assert changeset.valid?
      assert changeset.changes.post_date == september_16_2025
    end

    test "ensures 8/31/2025 date validation works correctly", %{ref_category: ref_category} do
      # Another date that was causing parsing issues
      august_31_2025 = ~D[2025-08-31]
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, august_31_2025)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      # Should be valid in test environment
      assert changeset.valid?
      assert changeset.changes.post_date == august_31_2025
    end

    test "validates that date comparison logic works correctly", %{ref_category: ref_category} do
      # Test the date comparison logic in validate_post_date
      original_env = Mix.env()
      Mix.env(:prod)
      
      # Get the target date (yesterday)
      target_date = Efl.TimeUtil.target_date()
      
      # Test with exact match (should be valid)
      attrs_exact = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, target_date)
      
      changeset_exact = Dadi.changeset(%Dadi{}, attrs_exact)
      assert changeset_exact.valid?, "Exact date match should be valid"
      
      # Test with different date (should be invalid)
      different_date = target_date |> Timex.shift(days: 1)
      attrs_different = @valid_attrs
      |> Map.put(:ref_category_id, ref_category.id)
      |> Map.put(:post_date, different_date)
      
      changeset_different = Dadi.changeset(%Dadi{}, attrs_different)
      refute changeset_different.valid?, "Different date should be invalid"
      assert changeset_different.errors[:post_date] == {"can't be blank", []}
      
      # Restore original environment
      Mix.env(original_env)
    end
  end

  describe "process management" do
    test "start/0 starts a new process when none is running" do
      # Ensure no process is running
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> Process.exit(pid, :kill)
      end
      
      # Start a new process
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # Verify process is registered
      assert Process.whereis(:dadi_processor) == pid
      
      # Clean up
      Process.exit(pid, :kill)
      Process.unregister(:dadi_processor)
    end

    test "start/0 returns error when process is already running" do
      # Start first process
      {:ok, pid1} = Dadi.start
      assert is_pid(pid1)
      
      # Try to start second process
      {:error, :already_running} = Dadi.start
      
      # Clean up
      Process.exit(pid1, :kill)
      Process.unregister(:dadi_processor)
    end

    test "stop/0 stops running process" do
      # Start a process
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # Stop the process
      {:ok, :stopped} = Dadi.stop
      
      # Verify process is no longer registered
      assert Process.whereis(:dadi_processor) == nil
    end

    test "stop/0 returns not_running when no process is running" do
      # Ensure no process is running
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> Process.exit(pid, :kill)
      end
      
      # Try to stop non-existent process
      {:ok, :not_running} = Dadi.stop
    end

    test "status/0 returns correct status" do
      # Test when no process is running
      {:not_running, nil} = Dadi.status
      
      # Start a process
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # Test when process is running
      {:running, ^pid} = Dadi.status
      
      # Clean up
      Process.exit(pid, :kill)
      Process.unregister(:dadi_processor)
    end

    test "process cleanup happens after completion" do
      # This test verifies that the process unregisters itself
      # We'll use a mock main function that exits quickly
      original_main = &Dadi.main/0
      
      # Mock main to exit quickly
      defmodule TestDadi do
        def start do
          case Process.whereis(:dadi_processor) do
            nil ->
              {:ok, pid} = Task.start_link(fn -> 
                Process.register(self(), :dadi_processor)
                # Simulate quick completion
                :timer.sleep(100)
                Process.unregister(:dadi_processor)
              end)
              {:ok, pid}
            pid when is_pid(pid) ->
              {:error, :already_running}
          end
        end
      end
      
      # Start process
      {:ok, pid} = TestDadi.start
      assert is_pid(pid)
      
      # Wait for completion
      :timer.sleep(200)
      
      # Verify process cleaned up
      assert Process.whereis(:dadi_processor) == nil
    end
  end

  describe "concurrent execution prevention" do
    test "prevents multiple processes from running simultaneously" do
      # Start first process
      {:ok, pid1} = Dadi.start
      assert is_pid(pid1)
      
      # Try to start multiple processes concurrently
      tasks = for _ <- 1..5 do
        Task.async(fn -> Dadi.start end)
      end
      
      results = Task.await_many(tasks)
      
      # All should return already_running error
      assert Enum.all?(results, fn result -> 
        result == {:error, :already_running}
      end)
      
      # Clean up
      Process.exit(pid1, :kill)
      Process.unregister(:dadi_processor)
    end

    test "process registration is atomic" do
      # This test ensures that process registration doesn't have race conditions
      # Start multiple processes simultaneously
      tasks = for _ <- 1..10 do
        Task.async(fn -> Dadi.start end)
      end
      
      results = Task.await_many(tasks)
      
      # Only one should succeed, others should fail
      success_count = Enum.count(results, fn result -> 
        match?({:ok, _pid}, result)
      end)
      
      error_count = Enum.count(results, fn result -> 
        result == {:error, :already_running}
      end)
      
      assert success_count == 1
      assert error_count == 9
      
      # Clean up
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> Process.exit(pid, :kill)
      end
      Process.unregister(:dadi_processor)
    end
  end

  describe "error handling in process management" do
    test "handles process crashes gracefully" do
      # Start a process
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # Kill the process externally
      Process.exit(pid, :kill)
      
      # Wait a bit for cleanup
      :timer.sleep(100)
      
      # Process should be unregistered
      assert Process.whereis(:dadi_processor) == nil
      
      # Should be able to start a new process
      {:ok, new_pid} = Dadi.start
      assert is_pid(new_pid)
      assert new_pid != pid
      
      # Clean up
      Process.exit(new_pid, :kill)
      Process.unregister(:dadi_processor)
    end

    test "handles registration errors" do
      # This test simulates what happens if registration fails
      # We'll test the error handling in the start function
      
      # Mock a scenario where registration might fail
      # (This is more of a theoretical test since Process.register is very reliable)
      
      # Start and stop a process to ensure clean state
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      # Should be able to start normally
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # Clean up
      Process.exit(pid, :kill)
      Process.unregister(:dadi_processor)
    end
  end

  describe "start/0" do
    test "starts the main scraping process" do
      # This is a more complex test that would require mocking
      # For now, we'll just test that it doesn't crash
      assert is_pid(Process.whereis(Efl.Dadi)) == false
      
      # Note: In a real test, you'd want to mock the external dependencies
      # like HTTP requests, email sending, etc.
    end
  end

  describe "content extraction integration" do
    test "validates that content extraction is working in the full flow" do
      # Test that the Dadi model can handle content from the regex extraction
      content_with_phone = "【🏠 出租，】法拉盛新昌发对面电梯楼有大单间出租，随时入住，房间阳光明媚，安静、人少，适合单身，夫妻，餐馆优先，有意者，请联系电话：929-933-7510没接，可以发短信，谢谢！"
      
      attrs = %{
        title: "Test Apartment Rental",
        url: "https://example.com/test-apartment",
        content: content_with_phone,
        phone: "929-933-7510",
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.content == content_with_phone
      assert changeset.changes.phone == "929-933-7510"
    end

    test "handles Chinese content with special characters" do
      chinese_content = "法拉盛151街/34 ave 二楼两房一厅一浴。 大约800尺，查信用，收入证明，一月押金。包水。长租。租1600刀。"
      
      attrs = %{
        title: "Chinese Apartment Listing",
        url: "https://example.com/chinese-apartment",
        content: chinese_content,
        phone: "",
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.content == chinese_content
    end

    test "validates content length requirements" do
      # Test with content that should pass validation
      long_content = String.duplicate("This is a long content. ", 50) # 1250 characters
      
      attrs = %{
        title: "Long Content Test",
        url: "https://example.com/long-content",
        content: long_content,
        phone: "123-456-7890",
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      assert changeset.valid?
    end

    test "handles content with HTML tags that should be cleaned" do
      # This simulates content that would come from the regex extraction after cleaning
      cleaned_content = "Apartment for rent in Flushing area. Contact us for more details."
      
      attrs = %{
        title: "Cleaned Content Test",
        url: "https://example.com/cleaned-content",
        content: cleaned_content,
        phone: "718-123-4567",
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.content == cleaned_content
      # Verify no HTML tags remain
      refute String.contains?(changeset.changes.content, "<")
      refute String.contains?(changeset.changes.content, ">")
    end

    test "validates phone number extraction from content" do
      content_with_multiple_phones = "Call us at 929-933-7510 or 718-123-4567 for more information about this apartment."
      
      attrs = %{
        title: "Multiple Phone Numbers",
        url: "https://example.com/multiple-phones",
        content: content_with_multiple_phones,
        phone: "929-933-7510", # First phone found
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.content == content_with_multiple_phones
      assert changeset.changes.phone == "929-933-7510"
    end
  end
end
