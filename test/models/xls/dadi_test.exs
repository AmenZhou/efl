defmodule Efl.Xls.DadiTest do
  use Efl.ModelCase
  alias Efl.Xls.Dadi
  alias Efl.Dadi, as: DadiModel
  alias Efl.RefCategory

  setup do
    # Create a test category
    ref_category = %RefCategory{
      name: "test_category",
      url: "https://example.com/test"
    } |> Repo.insert!()

    # Create some test data
    dadi_post = %DadiModel{
      title: "Test Apartment",
      url: "https://example.com/test-apartment",
      content: "2 bedroom, 1 bath apartment for rent",
      phone: "123-456-7890",
      post_date: Efl.TimeUtil.target_date(),
      ref_category_id: ref_category.id
    } |> Repo.insert!()

    %{ref_category: ref_category, dadi_post: dadi_post}
  end

  describe "create_xls/0" do
    test "creates Excel file with data", %{ref_category: ref_category} do
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

    test "handles empty data gracefully" do
      # Clear all data
      Repo.delete_all(DadiModel)
      
      # Create Excel file with no data
      Dadi.create_xls()
      
      # File should still be created (with just headers)
      file_name = Dadi.file_name()
      assert File.exists?(file_name)
      
      # File should be small (just headers) - Excel files have minimum size
      file_size = File.stat!(file_name).size
      assert file_size < 20000  # Reasonable size for empty Excel file
      
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
end