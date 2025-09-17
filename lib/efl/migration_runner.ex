defmodule Efl.MigrationRunner do
  @moduledoc """
  Simple migration runner that works without Ecto.
  """

  def run_migrations do
    IO.puts("Running database migrations...")
    
    migrations = [
      "ALTER TABLE dadi MODIFY COLUMN content TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci",
      "ALTER TABLE dadi MODIFY COLUMN title VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci",
      "ALTER TABLE dadi MODIFY COLUMN url VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    ]

    Enum.each(migrations, fn sql ->
      case Efl.Database.execute_migration(sql) do
        {:ok, _} -> IO.puts("✅ Migration successful")
        {:error, reason} -> IO.puts("❌ Migration failed: #{inspect(reason)}")
      end
    end)
    
    IO.puts("Migration process completed!")
  end
end
