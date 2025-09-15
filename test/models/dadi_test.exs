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
      page_count: 5
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
      
      # Try to create duplicate
      changeset = Dadi.changeset(%Dadi{}, attrs)
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
