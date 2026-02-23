# Verify proxy count in DB. Usage: mix run scripts/verify_proxies.exs
# With Docker: docker compose run --rm app mix run scripts/verify_proxies.exs

alias Ecto.Adapters.SQL
alias Efl.Repo

case SQL.query(Repo, "SELECT COUNT(*) as cnt FROM proxies", []) do
  {:ok, %{rows: [[cnt]]}} ->
    IO.puts("proxies table: #{cnt} row(s)")

  {:ok, %{rows: []}} ->
    IO.puts("proxies table: 0 rows")

  {:error, err} ->
    IO.puts("Error: #{inspect(err)}")
    System.halt(1)
end

# Sample a few rows
case SQL.query(Repo, "SELECT id, ip, port, score FROM proxies ORDER BY id DESC LIMIT 5", []) do
  {:ok, %{columns: cols, rows: rows}} ->
    IO.puts("\nLatest 5 rows (id, ip, port, score):")
    Enum.each(rows, fn row -> IO.inspect(row) end)

  {:error, _} ->
    :ok
end
