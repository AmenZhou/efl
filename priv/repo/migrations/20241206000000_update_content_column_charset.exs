defmodule Efl.Repo.Migrations.UpdateContentColumnCharset do
  use Ecto.Migration

  def up do
    # Update the content column to use utf8mb4 character set and collation
    execute "ALTER TABLE dadi MODIFY COLUMN content TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    
    # Also update other text columns that might contain UTF-8 data
    execute "ALTER TABLE dadi MODIFY COLUMN title VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE dadi MODIFY COLUMN url VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
  end

  def down do
    # Revert back to default character set (latin1)
    execute "ALTER TABLE dadi MODIFY COLUMN content TEXT CHARACTER SET latin1 COLLATE latin1_swedish_ci"
    execute "ALTER TABLE dadi MODIFY COLUMN title VARCHAR(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci"
    execute "ALTER TABLE dadi MODIFY COLUMN url VARCHAR(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci"
  end
end
