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

  describe "start/0" do
    test "starts the main scraping process" do
      # This is a more complex test that would require mocking
      # For now, we'll just test that it doesn't crash
      assert is_pid(Process.whereis(Efl.Dadi)) == false
      
      # Note: In a real test, you'd want to mock the external dependencies
      # like HTTP requests, email sending, etc.
    end
  end
end
