defmodule Efl.DadiModelTest do
  use ExUnit.Case, async: true

  alias Efl.Dadi

  describe "changeset/2" do
    test "valid changeset with all fields" do
      attrs = %{
        title: "Test Post",
        url: "https://example.com/test",
        content: "Test content",
        phone: "123-456-7890",
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.title == "Test Post"
      assert changeset.changes.url == "https://example.com/test"
      assert changeset.changes.content == "Test content"
      assert changeset.changes.phone == "123-456-7890"
      assert changeset.changes.post_date == ~D[2024-01-15]
      assert changeset.changes.ref_category_id == 1
    end

    test "valid changeset without phone" do
      attrs = %{
        title: "Test Post",
        url: "https://example.com/test",
        content: "Test content",
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
      changeset = Dadi.changeset(%Dadi{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = Dadi.changeset(%Dadi{}, %{})
      
      refute changeset.valid?
      assert changeset.errors[:title] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:url] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:post_date] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:ref_category_id] == {"can't be blank", [validation: :required]}
    end
  end

  describe "update_changeset/2" do
    test "valid update changeset with content and phone" do
      dadi = %Dadi{
        title: "Original Title",
        url: "https://example.com/original",
        content: "Original content",
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
      update_attrs = %{
        content: "Updated content",
        phone: "987-654-3210"
      }
      
      changeset = Dadi.update_changeset(dadi, update_attrs)
      assert changeset.valid?
      assert changeset.changes.content == "Updated content"
      assert changeset.changes.phone == "987-654-3210"
    end

    test "valid update changeset with content only" do
      dadi = %Dadi{
        title: "Original Title",
        url: "https://example.com/original",
        content: "Original content",
        post_date: ~D[2024-01-15],
        ref_category_id: 1
      }
      
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
end
