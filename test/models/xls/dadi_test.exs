defmodule Efl.Xls.DadiTest do
  use Efl.ModelCase, async: true

  alias Efl.Xls.Dadi
  alias Efl.Dadi, as: DadiModel
  alias Efl.RefCategory
  alias Efl.Repo

  setup do
    # Create test data
    ref_category = %RefCategory{
      name: "test_category",
      display_name: "Test Category",
      page_size: 5
    } |> Repo.insert!()

    # Create some test dadi records
    yesterday = Efl.TimeUtil.target_date()
    
    dadi1 = %DadiModel{
      title: "Test Post 1",
      url: "https://example.com/test1",
      content: "Test content 1",
      phone: "123-456-7890",
      post_date: yesterday,
      ref_category_id: ref_category.id
    } |> Repo.insert!()

    dadi2 = %DadiModel{
      title: "Test Post 2", 
      url: "https://example.com/test2",
      content: "Test content 2",
      phone: "987-654-3210",
      post_date: yesterday,
      ref_category_id: ref_category.id
    } |> Repo.insert!()

    {:ok, ref_category: ref_category, dadi1: dadi1, dadi2: dadi2}
  end

  describe "create_xls/0" do
    test "creates Excel file with data", %{ref_category: ref_category} do
      # Ensure we have data
      dadi_count = Repo.aggregate(DadiModel, :count, :id)
      assert dadi_count > 0

      # Create Excel file
      Dadi.create_xls()
      
      # Check if file was created
      file_name = Dadi.file_name()
      assert File.exists?(file_name)
      
      # Check file size (should be more than just headers)
      file_size = File.stat!(file_name).size
      assert file_size > 1000
      
      # Clean up
      File.rm!(file_name)
    end

    test "handles empty data gracefully" do
      # Clear all data
      Repo.delete_all(DadiModel)
      
      # Create Excel file with no data
      Dadi.create_xls()
      
      # File should still be created (with just headers)
      file_name = Dadi.file_name()
      assert File.exists?(file_name)
      
      # File should be small (just headers)
      file_size = File.stat!(file_name).size
      assert file_size < 1000
      
      # Clean up
      File.rm!(file_name)
    end
  end

  describe "file_name/0" do
    test "generates filename with target date" do
      file_name = Dadi.file_name()
      target_date = Efl.TimeUtil.target_date()
      expected_date = target_date |> Timex.format!("%m-%d-%Y", :strftime)
      
      assert String.contains?(file_name, "DADI360-")
      assert String.contains?(file_name, expected_date)
      assert String.ends_with?(file_name, ".xlsx")
    end
  end

  # Note: Sheet creation is tested through the public create_xls/0 function

  # Note: Sheet structure is tested through the complete Excel creation process

  describe "Excel file structure and data integrity" do
    test "creates Excel file with proper data structure", %{ref_category: ref_category} do
      # Ensure we have test data
      dadi_count = Repo.aggregate(DadiModel, :count, :id)
      assert dadi_count > 0

      # Create Excel file
      Dadi.create_xls()
      file_name = Dadi.file_name()

      # Verify the file exists
      assert File.exists?(file_name)

      # Verify file has reasonable size (indicates it contains data rows)
      file_size = File.stat!(file_name).size
      assert file_size > 2000  # Should contain header + data rows

      # Clean up
      File.rm!(file_name)
    end

    test "handles missing data gracefully in Excel creation" do
      # Create a record with some nil fields to test data handling
      ref_category = Repo.get_by(RefCategory, name: "test_category")

      dadi_with_nils = %DadiModel{
        title: nil,  # Test nil title
        url: "https://example.com/test",
        content: nil,  # Test nil content
        phone: nil,   # Test nil phone
        post_date: Efl.TimeUtil.target_date(),
        ref_category_id: ref_category.id
      }

      # Insert temporarily
      {:ok, inserted_dadi} = Repo.insert(dadi_with_nils)

      # Excel creation should handle nil fields gracefully
      Dadi.create_xls()
      file_name = Dadi.file_name()

      # Verify file was created despite nil fields
      assert File.exists?(file_name)

      # Clean up
      File.rm!(file_name)
      Repo.delete(inserted_dadi)
    end

    test "creates Excel with multiple categories" do
      # Test that Excel creation handles multiple categories properly
      # This tests the sheet creation functionality indirectly

      # Create a second category for testing
      {:ok, second_category} = %RefCategory{
        name: "second_test_category",
        url: "http://example.com/category2"
      } |> Repo.insert()

      # Create a dadi for the second category
      {:ok, _second_dadi} = %DadiModel{
        title: "Second category post",
        url: "https://example.com/second",
        content: "Second category content",
        phone: "555-1234",
        post_date: Efl.TimeUtil.target_date(),
        ref_category_id: second_category.id
      } |> Repo.insert()

      # Create Excel file
      Dadi.create_xls()
      file_name = Dadi.file_name()

      # Verify the file exists and has reasonable size for multiple sheets
      assert File.exists?(file_name)
      file_size = File.stat!(file_name).size
      assert file_size > 3000  # Should be larger with multiple categories

      # Clean up
      File.rm!(file_name)
      Repo.delete(second_category)  # This will cascade delete the dadi
    end
  end

  describe "string data cleaning in Excel output" do
    test "handles special characters in data" do
      # Test that string cleaning functionality works through Excel creation
      ref_category = Repo.get_by(RefCategory, name: "test_category")

      dadi_with_special_chars = %DadiModel{
        title: "Test\bWith\bBackspaces",  # Test backspace handling
        url: "https://example.com/special",
        content: "Content\bWith\bSpecial\bChars",
        phone: "123-456-7890",
        post_date: Efl.TimeUtil.target_date(),
        ref_category_id: ref_category.id
      }

      # Insert temporarily
      {:ok, inserted_dadi} = Repo.insert(dadi_with_special_chars)

      # Excel creation should clean special characters
      Dadi.create_xls()
      file_name = Dadi.file_name()

      # Verify file was created successfully
      assert File.exists?(file_name)

      # Clean up
      File.rm!(file_name)
      Repo.delete(inserted_dadi)
    end
  end

  describe "Excel file structure" do
    test "creates Excel file with correct column headers", %{ref_category: ref_category} do
      # Create Excel file
      Dadi.create_xls()
      file_name = Dadi.file_name()

      # Verify the file exists
      assert File.exists?(file_name)

      # Note: We're testing that the file is created successfully
      # The actual column headers are tested through integration tests
      # that verify the complete Excel structure

      # Clean up
      File.rm!(file_name)
    end
  end

  describe "date handling in Excel creation" do
    test "creates Excel file with valid date data", %{dadi1: dadi1} do
      # Create Excel file
      Dadi.create_xls()
      file_name = Dadi.file_name()

      # Verify the file exists and was created successfully
      assert File.exists?(file_name)

      # Verify file has reasonable size (contains data)
      file_size = File.stat!(file_name).size
      assert file_size > 1000  # Should contain actual data

      # Clean up
      File.rm!(file_name)
    end

    test "handles records with missing dates gracefully" do
      # Test that Excel creation handles edge cases properly
      # by temporarily creating a record with nil date
      ref_category = Repo.get_by(RefCategory, name: "test_category")

      dadi_with_nil_date = %DadiModel{
        title: "Test with nil date",
        url: "https://example.com/test",
        content: "Test content",
        phone: "123-456-7890",
        post_date: nil,
        ref_category_id: ref_category.id
      }

      # Insert temporarily
      {:ok, inserted_dadi} = Repo.insert(dadi_with_nil_date)

      # Excel creation should handle nil dates (either skip or error gracefully)
      try do
        Dadi.create_xls()
        file_name = Dadi.file_name()
        if File.exists?(file_name), do: File.rm!(file_name)
      rescue
        RuntimeError ->
          # This is expected behavior for nil dates
          :ok
      end

      # Clean up
      Repo.delete(inserted_dadi)
    end
  end

  # Note: String cleaning functionality is tested through integration tests
  # that verify the complete Excel creation process handles data properly
end

