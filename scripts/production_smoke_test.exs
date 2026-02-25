# Production automation test — full DADI pipeline (real DB, real HTTP, optional email).
#
# Mirrors documents/manual_tests.ex for automated production/smoke testing.
#
# Usage:
#   MIX_ENV=prod mix run scripts/production_smoke_test.exs
#
# Optional env:
#   PRODUCTION_SKIP_EMAIL=1  — skip sending email (XLS still created)
#   PRODUCTION_SINGLE_CATEGORY=1 — after full run, also run create_items for one category only (extra check)
#
# Prerequisites:
#   - Production DB reachable (config :efl, Efl.Repo for current MIX_ENV).
#   - If the app is already running, stop it first to avoid port conflict, or run this from another host.
#
# Steps run (in order):
#   1. Efl.Repo.delete_all(Efl.Dadi)
#   2. Efl.Dadi.Category.create_all_items
#   3. Efl.Dadi.Post.update_contents (twice)
#   4. Efl.Xls.Dadi.create_xls
#   5. Efl.Mailer.send_email_with_xls (unless PRODUCTION_SKIP_EMAIL=1)
#   6. Efl.Proxy.fetch_from_api
#   7. [If PRODUCTION_SINGLE_CATEGORY=1] Efl.Dadi.Category.create_items(cat) for one category

alias Efl.Repo
alias Efl.Dadi
alias Efl.RefCategory
alias Efl.Dadi.Category
alias Efl.Dadi.Post
alias Efl.Xls.Dadi, as: XlsDadi
alias Efl.Mailer
alias Efl.Proxy

require Logger

defmodule ProductionSmokeTest do
  def run do
    Logger.info("=== Production smoke test started (MIX_ENV=#{System.get_env("MIX_ENV")}) ===")

    steps = [
      {"Delete all Dadi", &step_delete_dadi/0},
      {"Category.create_all_items", &step_create_all_items/0},
      {"Post.update_contents (1)", &step_update_contents/0},
      {"Post.update_contents (2)", &step_update_contents/0},
      {"Xls.Dadi.create_xls", &step_create_xls/0},
      {"Mailer.send_email_with_xls", &step_send_email/0},
      {"Proxy.fetch_from_api", &step_fetch_proxy/0},
      {"Single category create_items (optional)", &step_single_category/0}
    ]

    results =
      Enum.map(steps, fn {name, fun} ->
        Logger.info(">>> #{name}")
        result = run_step(name, fun)
        Logger.info("<<< #{name}: #{if result == :ok, do: "OK", else: "FAIL"}")
        {name, result}
      end)

    failed = Enum.filter(results, fn {_, r} -> r != :ok end)
    if failed == [] do
      Logger.info("=== Production smoke test completed successfully ===")
    else
      Logger.error("=== Production smoke test had #{length(failed)} failure(s) ===")
      Enum.each(failed, fn {name, err} -> Logger.error("  #{name}: #{inspect(err)}") end)
      System.halt(1)
    end
  end

  defp run_step(_name, fun) do
    try do
      case fun.() do
        :ok -> :ok
        {:ok, _} -> :ok
        {:error, _} = err -> err
        other -> {:error, other}
      end
    rescue
      e -> {:error, e}
    end
  end

  defp step_delete_dadi do
    Repo.delete_all(Dadi)
    :ok
  end

  defp step_create_all_items do
    Category.create_all_items()
    :ok
  end

  defp step_update_contents do
    Post.update_contents()
    :ok
  end

  defp step_create_xls do
    XlsDadi.create_xls()
    :ok
  end

  defp step_send_email do
    if System.get_env("PRODUCTION_SKIP_EMAIL") == "1" do
      Logger.info("Skipping email (PRODUCTION_SKIP_EMAIL=1)")
      :ok
    else
      case Mailer.send_email_with_xls() do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
        other -> {:error, other}
      end
    end
  end

  defp step_fetch_proxy do
    Proxy.fetch_from_api()
    :ok
  end

  defp step_single_category do
    if System.get_env("PRODUCTION_SINGLE_CATEGORY") != "1" do
      Logger.info("Skipping single-category step (set PRODUCTION_SINGLE_CATEGORY=1 to run)")
      :ok
    else
      # Use category from DB (e.g. BUSINESS_TRANS / 生意转让) or fallback struct
      cat =
        Repo.get_by(RefCategory, name: "BUSINESS_TRANS") ||
          Repo.get_by(RefCategory, name: "STORE_RENT") ||
          first_ref_category()

      if cat do
        Category.create_items(cat)
        :ok
      else
        Logger.warning("No ref category found for single-category test (run RefCategory.seeds first?)")
        :ok
      end
    end
  end

  defp first_ref_category do
    RefCategory |> Repo.all() |> List.first()
  end
end

# Start only Repo to avoid port conflict when app is not needed (e.g. running alongside another node).
# If you need full app (e.g. Proxy.Cache), remove this and rely on normal mix run app start.
Application.ensure_all_started(:efl)
ProductionSmokeTest.run()
