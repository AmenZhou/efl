# Production-style automation tests: full DADI pipeline (real HTTP, real DB).
# Same flow as documents/manual_tests.ex and scripts/production_smoke_test.exs.
#
# These tests are excluded by default (they hit real external sites and can be slow).
# Run explicitly:
#   mix test test/integration/production_flow_test.exs --include production:true
#
# Or run the script against prod DB instead:
#   MIX_ENV=prod mix run scripts/production_smoke_test.exs

defmodule Efl.ProductionFlowTest do
  use Efl.ModelCase, async: false

  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.RefCategory
  alias Efl.Dadi.Category
  alias Efl.Dadi.Post
  alias Efl.Xls.Dadi, as: XlsDadi
  alias Efl.Mailer
  alias Efl.Proxy

  @moduletag :production

  describe "full pipeline (mirrors manual_tests.ex)" do
    test "delete_all Dadi, create_all_items, update_contents, create_xls", _ do
      Repo.delete_all(Dadi)
      assert Repo.aggregate(Dadi, :count, :id) == 0

      Category.create_all_items()
      count_after_categories = Repo.aggregate(Dadi, :count, :id)
      assert count_after_categories >= 0, "create_all_items should complete"

      Post.update_contents()
      Post.update_contents()

      # create_xls reads from DB and writes file; no exception = success
      XlsDadi.create_xls()
      assert true
    end

    test "send_email_with_xls returns ok or error (no crash)", _ do
      result = Mailer.send_email_with_xls()
      assert result == {:ok, _} or match?({:error, _}, result) or result == :ok
    end

    test "Proxy.fetch_from_api completes", _ do
      Proxy.fetch_from_api()
      assert true
    end

    test "single category create_items (BUSINESS_TRANS or first)", _ do
      RefCategory.seeds()
      cat =
        Repo.get_by(RefCategory, name: "BUSINESS_TRANS") ||
          Repo.get_by(RefCategory, name: "STORE_RENT") ||
          Repo.all(RefCategory) |> List.first()

      assert cat != nil, "need at least one RefCategory (seeds)"
      Category.create_items(cat)
      # No exception = success
      assert true
    end
  end
end
