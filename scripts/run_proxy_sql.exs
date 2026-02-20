# Run priv/update_proxies.sql via Ecto Repo.
#
# Purpose:
#   Bulk-inserts proxy rows into the `proxies` table from the SQL file. The SQL file is
#   generated from an external proxy list; source: https://github.com/proxifly/free-proxy-list
#   (see README for direct download links: HTTP/HTTPS/SOCKS .txt, .json, .csv). Uses the app's
#   configured database (config :efl, Efl.Repo).
#
# Usage:
#   mix run scripts/run_proxy_sql.exs
#
# Prerequisites:
#   - Database must be reachable (e.g. Docker MySQL up, or MYSQL_HOST set for test).
#   - priv/update_proxies.sql must exist (regenerate from proxy list at the URL above if needed).
#
# See also:
#   - scripts/verify_proxies.exs — check row count and sample rows after running.
#   - priv/update_proxies.sql — batched INSERT statements (ip, port, score=10).

alias Ecto.Adapters.SQL
alias Efl.Repo

# Resolve path from project root and read the SQL file.
sql_path = Path.join(File.cwd!(), "priv/update_proxies.sql")
sql = File.read!(sql_path)

# Split into statements: by semicolon, trim whitespace, drop comments and empty.
# The SQL file contains multiple INSERT statements (batched for size).
statements =
  sql
  |> String.split(";")
  |> Enum.map(&String.trim/1)
  |> Enum.reject(&(String.starts_with?(&1, "--") or &1 == ""))

# Execute each statement through the Repo's connection pool.
results =
  Enum.map(statements, fn stmt ->
    case SQL.query(Repo, stmt, []) do
      {:ok, result} -> {:ok, result}
      {:error, err} -> {:error, err}
    end
  end)

oks = Enum.count(results, &match?({:ok, _}, &1))
errs = Enum.filter(results, &match?({:error, _}, &1))

if errs == [] do
  IO.puts("OK: Executed #{oks} statement(s).")
else
  IO.puts("Errors: #{length(errs)}")
  Enum.each(errs, fn {:error, e} -> IO.inspect(e, label: "Error") end)
  System.halt(1)
end
