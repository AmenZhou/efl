defmodule Efl.Database do
  @moduledoc """
  Direct MyXQL database operations without Ecto.
  This replaces Ecto with direct SQL operations.
  """

  @db_config %{
    hostname: "localhost",
    username: "hzhou",
    password: "",
    database: "classification_utility_dev",
    port: 3306,
    charset: "utf8mb4"
  }

  def start_link do
    MyXQL.start_link(@db_config)
  end

  def query(sql, params \\ []) do
    case MyXQL.query(connection(), sql, params) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  def execute_migration(sql) do
    case MyXQL.query(connection(), sql) do
      {:ok, result} -> 
        IO.puts("Migration executed successfully: #{sql}")
        {:ok, result}
      {:error, reason} -> 
        IO.puts("Migration failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp connection do
    # In a real app, you'd want to use a connection pool
    # For now, we'll create a new connection for each query
    {:ok, conn} = MyXQL.start_link(@db_config)
    conn
  end

  # Helper functions for common operations
  def insert(table, data) do
    fields = Map.keys(data) |> Enum.join(", ")
    placeholders = Map.keys(data) |> Enum.map(fn _ -> "?" end) |> Enum.join(", ")
    values = Map.values(data)
    
    sql = "INSERT INTO #{table} (#{fields}) VALUES (#{placeholders})"
    query(sql, values)
  end

  def update(table, id, data) do
    set_clause = Map.keys(data) |> Enum.map(fn key -> "#{key} = ?" end) |> Enum.join(", ")
    values = Map.values(data) ++ [id]
    
    sql = "UPDATE #{table} SET #{set_clause} WHERE id = ?"
    query(sql, values)
  end

  def select(table, where_clause \\ "", params \\ []) do
    sql = "SELECT * FROM #{table}"
    sql = if where_clause != "", do: sql <> " WHERE " <> where_clause, else: sql
    query(sql, params)
  end
end
