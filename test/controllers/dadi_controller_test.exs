defmodule Efl.DadiControllerTest do
  use Efl.ConnCase, async: true

  alias Efl.Dadi
  alias Efl.RefCategory

  setup do
    # Create test data
    ref_category = %RefCategory{
      name: "test_category",
      display_name: "Test Category",
      page_count: 5
    } |> Repo.insert!()

    dadi_post = %Dadi{
      title: "Test Post",
      url: "https://example.com/test",
      content: "Test content",
      phone: "123-456-7890",
      post_date: ~D[2024-01-15],
      ref_category_id: ref_category.id
    } |> Repo.insert!()

    {:ok, ref_category: ref_category, dadi_post: dadi_post}
  end

  describe "GET /" do
    test "renders the index page with posts", %{conn: conn, dadi_post: dadi_post} do
      conn = get(conn, "/")
      
      assert html_response(conn, 200) =~ "Test Post"
      assert html_response(conn, 200) =~ "https://example.com/test"
    end

    test "renders empty page when no posts exist", %{conn: conn} do
      # Clear all posts
      Repo.delete_all(Dadi)
      
      conn = get(conn, "/")
      assert html_response(conn, 200)
    end
  end

  describe "GET /dadi/scratch" do
    test "returns permission denied for non-localhost IP", %{conn: conn} do
      # Mock remote_ip to simulate non-localhost
      conn = %{conn | remote_ip: {192, 168, 1, 100}}
      
      conn = get(conn, "/dadi/scratch")
      assert text_response(conn, 200) =~ "No permission"
    end

    test "allows localhost IP to start scraping", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      conn = get(conn, "/dadi/scratch")
      assert text_response(conn, 200) =~ "Start scratching DD360..."
    end
  end
end
