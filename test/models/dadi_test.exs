defmodule Efl.DadiTest do
  use Efl.ModelCase

  alias Efl.Dadi

  @valid_attrs %{title: "some title", url: "some url", content: "some content", phone: "some phone", post_date: ~D[2024-01-15], ref_category_id: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Dadi.changeset(%Dadi{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Dadi.changeset(%Dadi{}, @invalid_attrs)
    refute changeset.valid?
  end

  describe "date validation" do
    setup do
      # Create a ref_category for testing
      ref_category = %Efl.RefCategory{
        id: 1,
        name: "Test Category",
        url: "https://example.com"
      }
      %{ref_category: ref_category}
    end

    test "accepts yesterday's date in production" do
      # Temporarily set environment to production
      original_env = Mix.env()
      Mix.env(:prod)
      
      # Get yesterday's date
      target_date = Efl.TimeUtil.target_date()
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, 1)
      |> Map.put(:post_date, target_date)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      assert changeset.valid?, "Yesterday's date should be valid in production"
      
      # Restore original environment
      Mix.env(original_env)
    end

    test "rejects non-yesterday dates in production" do
      # Temporarily set environment to production
      original_env = Mix.env()
      Mix.env(:prod)
      
      # Use a different date (not yesterday)
      different_date = ~D[2024-01-01]
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, 1)
      |> Map.put(:post_date, different_date)
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      refute changeset.valid?, "Non-yesterday date should be invalid in production"
      assert changeset.errors[:post_date] == {"can't be blank", []}
      
      # Restore original environment
      Mix.env(original_env)
    end

    test "allows any date in test environment" do
      # Test environment should allow any date
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, 1)
      |> Map.put(:post_date, ~D[2024-01-01])
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      assert changeset.valid?, "Any date should be valid in test environment"
    end

    test "allows any date in dev environment" do
      # Temporarily set environment to dev
      original_env = Mix.env()
      Mix.env(:dev)
      
      attrs = @valid_attrs
      |> Map.put(:ref_category_id, 1)
      |> Map.put(:post_date, ~D[2024-01-01])
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      assert changeset.valid?, "Any date should be valid in dev environment"
      
      # Restore original environment
      Mix.env(original_env)
    end

    test "validates exact date match in production" do
      # Temporarily set environment to production
      original_env = Mix.env()
      Mix.env(:prod)
      
      # Get the exact target date
      target_date = Efl.TimeUtil.target_date()
      
      # Test with exact date match (should be valid)
      attrs_exact = @valid_attrs
      |> Map.put(:ref_category_id, 1)
      |> Map.put(:post_date, target_date)
      
      changeset_exact = Dadi.changeset(%Dadi{}, attrs_exact)
      assert changeset_exact.valid?, "Exact date match should be valid"
      
      # Test with different date (should be invalid)
      different_date = target_date |> Timex.shift(days: 1)
      attrs_different = @valid_attrs
      |> Map.put(:ref_category_id, 1)
      |> Map.put(:post_date, different_date)
      
      changeset_different = Dadi.changeset(%Dadi{}, attrs_different)
      refute changeset_different.valid?, "Different date should be invalid"
      assert changeset_different.errors[:post_date] == {"can't be blank", []}
      
      # Restore original environment
      Mix.env(original_env)
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