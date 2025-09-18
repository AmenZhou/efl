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

  describe "sheets/0" do
    test "creates sheets for each category", %{ref_category: ref_category} do
      sheets = Dadi.sheets()
      
      # Should have at least one sheet
      assert length(sheets) > 0
      
      # Each sheet should have a name and rows
      Enum.each(sheets, fn sheet ->
        assert sheet.name != nil
        assert is_list(sheet.rows)
        assert length(sheet.rows) > 0  # Should have at least header row
      end)
    end
  end

  describe "one_sheet/1" do
    test "creates sheet with correct structure", %{ref_category: ref_category} do
      # Preload the dadis for the category
      ref_category = Repo.preload(ref_category, :dadis)
      
      sheet = Dadi.one_sheet(ref_category)
      
      assert sheet.name == ref_category.display_name
      assert is_list(sheet.rows)
      assert length(sheet.rows) > 0
    end
  end

  describe "rows/1" do
    test "creates rows with correct structure", %{ref_category: ref_category} do
      # Preload the dadis for the category
      ref_category = Repo.preload(ref_category, :dadis)
      
      rows = Dadi.rows(ref_category.dadis)
      
      # Should have header row plus data rows
      assert length(rows) > 1
      
      # First row should be headers
      header_row = List.first(rows)
      expected_headers = ["发布日期", "电话", "标题", "内容"]
      assert header_row == expected_headers
      
      # Data rows should have 4 columns
      data_rows = Enum.drop(rows, 1)
      Enum.each(data_rows, fn row ->
        assert length(row) == 4
      end)
    end
  end

  describe "one_row/1" do
    test "creates row with correct data", %{dadi1: dadi1} do
      row = Dadi.one_row(dadi1)
      
      assert length(row) == 4
      assert Enum.at(row, 2) == dadi1.title  # Title column
      assert Enum.at(row, 3) == dadi1.content  # Content column
      assert Enum.at(row, 1) == dadi1.phone  # Phone column
    end

    test "handles missing data gracefully" do
      dadi_with_nils = %DadiModel{
        title: nil,
        url: "https://example.com/test",
        content: nil,
        phone: nil,
        post_date: Efl.TimeUtil.target_date(),
        ref_category_id: 1
      }
      
      row = Dadi.one_row(dadi_with_nils)
      
      assert length(row) == 4
      assert Enum.at(row, 2) == ""  # Empty string for nil title
      assert Enum.at(row, 3) == ""  # Empty string for nil content
      assert Enum.at(row, 1) == ""  # Empty string for nil phone
    end
  end

  describe "titles/0" do
    test "returns correct column titles" do
      titles = Dadi.titles()
      expected_titles = ["发布日期", "电话", "标题", "内容"]
      
      assert titles == expected_titles
    end
  end

  describe "post_date/1" do
    test "formats date correctly", %{dadi1: dadi1} do
      formatted_date = Dadi.post_date(dadi1)
      
      # Should be in MM/DD/YYYY format
      assert String.match?(formatted_date, ~r/\d{2}\/\d{2}\/\d{4}/)
    end

    test "handles nil date gracefully" do
      dadi_with_nil_date = %DadiModel{post_date: nil}
      
      # Should raise an error for nil date
      assert_raise RuntimeError, fn ->
        Dadi.post_date(dadi_with_nil_date)
      end
    end
  end

  describe "clean_up_string/1" do
    test "removes backspace characters" do
      dirty_string = "Test\bString\bWith\bBackspaces"
      clean_string = Dadi.clean_up_string(dirty_string)
      
      assert clean_string == "TestStringWithBackspaces"
    end

    test "handles nil input" do
      clean_string = Dadi.clean_up_string(nil)
      assert clean_string == ""
    end

    test "handles empty string" do
      clean_string = Dadi.clean_up_string("")
      assert clean_string == ""
    end
  end
end
